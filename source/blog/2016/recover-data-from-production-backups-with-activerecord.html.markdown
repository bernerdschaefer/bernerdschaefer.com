---
date: 2016-04-13
title: "Recover Data from Production Backups with ActiveRecord"
teaser: >
  Sometimes things go awry with production data and you need to recover.
  Here's one way to do it.
robots: https://robots.thoughtbot.com/recover-data-from-production-backups-with-activerecord
---

What follows is a story about things going wrong with production data.
But don't worry, this one has a happy ending!

We've been working on a product which tracks interesting information about
companies, pulling data from a number of different sources. Users can then
interact with these company records by leaving notes, following them, and
updating their financials.

The data model, then, looks like this:

```ruby
class Company < ActiveRecord::Base
  has_many :financials
  has_many :followed_companies
  has_many :followers, through: :followed_companies, source: :user
  has_many :notes
end

class Financial < ActiveRecord::Base
  belongs_to :company
end

class FollowedCompany < ActiveRecord::Base
  belongs_to :company
  belongs_to :user
end

class Note < ActiveRecord::Base
  belongs_to :company
end
```

`Note` and `FollowedCompany` records are created based on user interactions,
while `Company` and `Financial` records are created by automated systems,
though users can edit them after they're created.

One of the tricky things in this system is that we need to combine multiple
data sources to get the information we need for a company and its financials --
but the sources often don't agree on details. For example, one source might
claim a company has 25 employees, while another claims it has 50. Sometimes,
they might not even agree on the company's name, like "Frozzle" and "Frozzle,
Inc."

In the case of employee count and similar data disagreements, we were able to
pick which source we trust more to accurately report that data, and default to
their value. When sources disagree about things like a company's name, though,
we can end up with duplicate companies.

That's why we started building a system to merge duplicate companies together.

When two companies are found to be duplicates we merge them with this process:

  1. Call the older of the companies the canonical company, and the newer the
     duplicate.

  2. Assign all of the duplicate company's associations to the canonical one:

    ```ruby
    duplicate.financials.update_all(company: canonical)
    duplicate.followed_companies.update_all(company: canonical)
    duplicate.notes.update_all(company: canonical)
    ```

  3. Mark the duplicate as merged by adding a notice to their name and
     recording which company they were merged into:

    ```ruby
    duplicate.update(
      name: "#{duplicate.name} (merged)",
      merged_to: canonical,
    )
    ```

But how do we know which companies to merge?

We've gone through a few iterations of this. Our first version only merged
companies with identical names. Later versions worked similarly, but also
ignored capitalization, whitespace, and punctuation.

But those versions really only dealt with the most obvious cases. But we still
had a lot of companies like "Frozzle" and "Frozzle, Inc.", or "Quibbles LLC"
and "Quibbles LTD".

So we put together another version to handle cases like that, and rolled it
out. We took a database backup, and then ran the deduplication process. It was
able to find around 1000 duplicate companies, and we confirmed that "Frozzle,
Inc" was merged away, so everything looked good, and we moved on to other
features.

Then we started seeing some strange production errors and bug reports over the
next few days. About a week and a half after the rollout, we discovered what
was going on: the new duplicate detector had incorrectly flagged a number of
unrelated companies as duplicates.

Note that above we stored what company a duplicate was merged into, but did not
do the same for its associations. That meant we couldn't use the database
directly to restore things to normal. We also weren't logging the sequence of
operations being done, which we could have used to reverse the process.

We were in a tricky spot. We had production data problems that we'd need to
roll back, but users had been interacting with the system for almost two weeks,
and we couldn't undo all of their work!

We reverted our new duplicate detector, and started brainstorming solutions.
The most promising solution seemed to be first to restore the pre-rollout
backup to a separate database, and then figure out what associations the
incorrectly merged companies had before, so that they could be re-assigned. In
pseudocode, we wanted to do something like:

```ruby
Company.incorrectly_merged.each do |company|
  company.backup_financials.each do |financial|
    Financial.where(id: financial.id).update!(comapny: company)
  end

  # repeat for followed companies and notes

  company.update!(
    name: company.name.without_merge_notice,
    merged_to: nil,
  )
end
```

We originally thought we'd do this in a series of steps, by writing some
scripts which connected to the backup database and exported data as a CSV, and
then other scripts which would use the CSV to update production data.

But in the end, we were actually able to do it with a single script, leveraging
ActiveRecord tools to write something very similar to the pseudocode above.

## Restore the backup locally

The project was deployed on Heroku and using [Heroku's PGBackups
feature][pgbackups] for both scheduled (daily) and manual backups.

We had already captured a backup of the production database before rolling out
the faulty process with `heroku pg:backups capture --app app-production`. That
backup was assigned an identifier by Heroku, in this case b046.

To restore that backup locally, then, we used:

```
$ curl -o backup.dump `heroku pg:backups public-url b046`
$ createdb backup
$ pg_restore -d backup backup.dump
```

With a complete copy of production data available locally, we were able to
start scripting the recovery process.

## Configure a named ActiveRecord connection

The first step was to add some new entries to `config/database.yml`:

```yaml
backup:
  <<: *default
  database: backup

remote_production:
  <<: *deploy
  url: postgres://.../production
```

## Define new models prefixed with `Backup`

```ruby
ActiveRecord::Base.establish_connection :remote_production

class BackupFinancial < ActiveRecord::Base
  establish_connection :backup
  self.table_name = "financials"
end

class BackupFollowedCompany < ActiveRecord::Base
  establish_connection :backup
  self.table_name = "followed_companies"
end

class BackupNote < ActiveRecord::Base
  establish_connection :backup
  self.table_name = "notes"
end
```

This will allow us to talk to both the production database and the backup at
the same time. The normal models (`Note`, `Financial`) will point to
production, and the models in the script (`BackupNote`) will point to the
backup database.

## Write the script, with print debugging

We'll need some helper functions, starting with one to clean up the names of
merged companies:

```ruby
def strip_merge_notice(name)
  merge_notice = / \(merged\)\Z/

  if name =~ merge_notice
    name.sub(merge_notice, "")
  else
    raise "Expected #{name.inspect} to match #{merge_notice.inspect}"
  end
end
```

Then a function for printing structured log information, which we can use to
debug or reverse this script if something goes wrong:

```ruby
# log_info(company: 1, name: "bar", ids: [2, 3])
#   => company=1 name="bar" ids=[2,3]
def log_info(attributes)
  line = attributes.
    map { |key, value| [key, value.inspect].join("=") }.
    join(" ")

  puts line
end
```

We'll also have a helper to restore a company's association:

```ruby
def restore_merged_association(company_id, backup_model, real_model)
  backup_ids = backup_model.
    where(company_id: company_id).
    pluck(:id)

  log_info(
    company: company_id,
    real_model.table_name => backup_ids.join(","),
  )

  real_model.
    where(id: backup_ids).
    update_all(company_id: company_id)
end
```

## Run script in transaction

And finally, we can put it all together:

```ruby
recently_merged_companies = Company.
  where.not(merged_to_id: nil).
  where("updated_at >= ?", Date.parse("2016-03-08"))

ActiveRecord::Base.transaction do
  recently_merged_companies.each do |company|
    new_name = strip_merge_notice(company.name)

    log_info(
      company: company.id,
      name: new_name,
      previous_name: company.name,
      previous_merged_to: company.merged_to_id,
    )
    company.update!(name: new_name, merged_to: nil)

    restore_merged_association company.id, BackupFinancial, Financial
    restore_merged_association company.id, BackupFollowedCompany, FollowedCompany
    restore_merged_association company.id, BackupNote, Note
  end
end
```

At this point, the script was ready for a few rounds of local iteration, before
we finally ran it against production with `rails runner unmerge.rb`. It
successfully rolled back the important associations that had been lost,
without losing any information that our users had entered in the mean time!

## What did we learn?

Once the dust had settled, we had a bit of time to reflect on what went wrong
and how to improve going forward:

### Backup before changing production data

We were already doing this, but it is important to restate. We couldn't
have recovered from this if we hadn't taken a backup before we rolled out
our changes.

### Log structured information from tasks

It would have been much easier to recover if we had logged the operations
in the deduplication process like we did in our recovery script. We likely
wouldn't have even needed the backups.

### Consider the rollback strategy

Our original script was optimistic about its correctness and didn't account
for the possibility of rollback. In retrospect, it may have made sense to
build it with an eye towards being easy to undo.

We also learned some things along the way while building the recovery script
itself:

  * You can have multiple models communicate with the same table by giving them
    unique names (like `BackupNote` above) and using `self.table_name=` to
    select the table.

  * You can connect to multiple databases at the same time with `ActiveRecord`!
    It's particularly interesting that different [models can be attached to different databases using `establish_connection`][ar-connection-adapter].

  * You can run a script like the recovery script multiple times and still
    check its effects by using transaction rollbacks and `pry`:

    ```ruby
    ActiveRecord::Base.transaction do
      # do work...

      binding.pry
      raise ActiveRecord::Rollback
    end
    ```

  [ar-connection-adapter]: http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionHandler.html
  [pgbackups]: https://devcenter.heroku.com/articles/heroku-postgres-backups

