---
title: "Multi-Locale Cucumber Features"
teaser: >
  Your site is available in multiple languages. How do you write features that
  ensure everything works regardless of the language?
---

So here's the problem: Your site is available in multiple languages. How do you
write features that ensure everything works regardless of the language?

I can imagine some truly clever solutions to this problem. This isn't one of
them. Instead, this is a practical approach to solving the problem -- with the
assumption that you're not using your features to communicate with
non-technical stakeholders.

Let's start with this simple feature describing a user logging in and viewing
his profile, and then see how we can transform it to suit our needs:

```
Feature: User views profile

  Scenario:
    Given I am logged in as a normal user
    When I go to the home page
    And I follow "Profile"
    Then I should see "Your Profile"
```

## Step 1: Use your translation keys

Okay. While that feature might pass, it's not going to work if we change the
default locale -- and it won't even work if we change our translation keys, so
let's change it up a bit:

<div class="highlight">
<pre>
    Given I am logged in as a normal user
    When I go to the home page
    And I follow <strong>t(profile)</strong>
    Then I should see <strong>t(your_profile)</strong>
</pre>
</div>

Pretty? No. But it should be familiar to anyone who's used the I18n gem, and
it's super easy to plug into cucumber:

```ruby
# features/step_definitions/locale_steps.rb

# Allows translation within cucumber features.
#
#   When I follow t(self_generated)
#     => When I follow "#{t(:self_generated)}"
#
Given(
/ ^
  (.*)              # I should see
  (t\(([^)]+)\))    # t(self_generated)
  (.*)              # within "#main"
  $
/x) do |first, _, key, last|
  Given %Q[#{first}"#{t(key)}"#{last}]
end
```

## Step 2: Test multiple locales

Now that we're using our translation keys, we can enhance our feature to
test against multiple locales. We'll want something like this:

<div class="highlight">
<pre>
Feature: User views profile

  Scenario:
    <strong>Given my locale is "en"</strong>
    And I am logged in as a normal user
    When I go to the home page
    And I follow t(profile)
    Then I should see t(your_profile)

  Scenario:
    <strong>Given my locale is "de"</strong>
    And I am logged in as a normal user
    When I go to the home page
    And I follow t(profile)
    Then I should see t(your_profile)
</pre>
</div>

This, too, is easy to support. We can add the following step to our locale
steps:

```ruby
# features/step_definitions/locale_steps.rb

Given /^my locale is "([^"]*)"$/ do |locale|
  I18n.locale = locale
end
```

And then add some cleanup code into our support files, to prevent the locale
from one scenario bleeding into the others.

```ruby
# features/support/locale.rb

After do
  I18n.locale = I18n.default_locale
end
```

## Step 3: Use scenario outlines

We could stop there.. but we're not done yet! We certainly don't want to
duplicate (or triplicate, or...) all of our scenarios, so let's use a scenario
outline to clean this up:

<div class="highlight">
<pre>
Feature: User views profile

  Scenario Outline:
    <strong>Given my locale is "&lt;locale&gt;"</strong>
    And I am logged in as a normal user
    When I go to the home page
    And I follow t(profile)
    Then I should see t(your_profile)

    <strong>Examples:
      | locale |
      | en     |
      | de     |</strong>
</pre>
</div>

And there we go! Now we've verified that our UI works in both English and
German, with just a handful of new step definitions. Happy cuking!
