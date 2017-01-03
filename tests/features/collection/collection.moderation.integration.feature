@api
Feature: As a user of the website
  I want to be able to perform available transitions
  according to the state of the entity and the graph they are stored in.

  Scenario: Check availability of actions depending on the state and the graph.
    Given users:
      | name        | roles     |
      | Cornelius   |           |
      | Tina Butler | moderator |
    And the following contact:
      | email | martykelley@bar.com |
      | name  | Marty Kelley        |
    And the following owner:
      | name            |
      | Martin Gonzalez |
    And the following collections:
      | title                      | description                | logo     | banner     | owner           | contact information | state            | policy domain |
      | Willing Fairy              | Willing Fairy              | logo.png | banner.jpg | Martin Gonzalez | Marty Kelley        | draft            | Statistics    |
      | The Fallen Thoughts        | The Fallen Thoughts        | logo.png | banner.jpg | Martin Gonzalez | Marty Kelley        | proposed         | EU finance    |
      | Destruction of Scent       | Destruction of Scent       | logo.png | banner.jpg | Martin Gonzalez | Marty Kelley        | validated        | eProcurement  |
      | The School's Stars         | The School's Stars         | logo.png | banner.jpg | Martin Gonzalez | Marty Kelley        | archival_request | eJustice      |
      | The Beginning of the Fairy | The Beginning of the Fairy | logo.png | banner.jpg | Martin Gonzalez | Marty Kelley        | deletion_request | Employment    |
      | Boy in the Dreams          | Boy in the Dreams          | logo.png | banner.jpg | Martin Gonzalez | Marty Kelley        | archived         | eHealth       |
    And the following collection user memberships:
      | collection           | user      | roles              |
      | Destruction of Scent | Cornelius | owner, facilitator |
    When I am logged in as a "facilitator" of the "Willing Fairy" collection
    And I go to the homepage of the "Willing Fairy" collection
    Then I should see the heading "Willing Fairy"
    And I should see the link "View draft"
    # @todo: Fix the visibility issue.
    But I should see the link "View"
    And I should see the link "Edit" in the "Entity actions" region

    # I should not be able to view draft collections I'm not a facilitator of.
    When I go to the homepage of the "The Fallen Thoughts" collection
    Then I should see the heading "Access denied"

    When I am logged in as a "facilitator" of the "Destruction of Scent" collection
    And I go to the homepage of the "Destruction of Scent" collection
    Then I should see the heading "Destruction of Scent"
    # Since it's validated, the normal view is the published view and the
    # "View draft" should not be shown.
    And I should not see the link "View Draft"

    # Edit as facilitator and save as draft.
    When I click "Edit"
    And I fill in "Title" with "Construction of Scent"
    And I press "Save as draft"

    # The page redirects to the canonical view after editing.
    Then I should see the heading "Destruction of Scent"
    And I should not see the heading "Construction of Scent"
    And I should see the link "View draft"
    When I click "View draft"
    # The header still shows the published title but the draft title is included
    # in the page.
    Then I should see the heading "Construction of Scent"

    # Publish draft version of the collection.
    When I am logged in as a moderator
    And I go to the homepage of the "Construction of Scent" collection
    And I click "Edit"
    And I press "Publish"
    Then I should see the heading "Construction of Scent"
    And I should not see the link "View draft"
    But I should see the link "View"

    # Ensure that the users do not lose their membership.
    When I am logged in as "Cornelius"
    And I go to the homepage of the "Construction of Scent" collection
    Then I should not see the link "View Draft"
    But I should see the link "Edit" in the "Entity actions" region
