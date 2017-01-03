@api
Feature: As a user of the website
  I want to be able to perform available transitions
  according to the state of the entity and the graph they are stored in.

  Scenario: Check availability of actions depending on the state and the graph.
    Given users:
      | name            | pass            | roles     |
      | Hulk            | big_green_puppy |           |
      | Captain America | star_shield     | moderator |
    And the following contact:
      | email | crabbypatties@bar.com |
      | name  | Crusty crab           |
    And the following owner:
      | name    | type                  |
      | Mr Crab | Private Individual(s) |
    And the following solutions:
      | title                    | description                | logo     | banner     | owner   | contact information | solution type     | state            | policy domain |
      | Professional Dreams      | Azure ship                 | logo.png | banner.jpg | Mr Crab | Crusty crab         | [ABB169] Business | draft            | eInclusion    |
      | The Falling Swords       | The Falling Swords         | logo.png | banner.jpg | Mr Crab | Crusty crab         | [ABB169] Business | proposed         | eInclusion    |
      | Flight of Night          | Rose of Doors              | logo.png | banner.jpg | Mr Crab | Crusty crab         | [ABB169] Business | validated        | eInclusion    |
      | The Streams of the Lover | The Ice's Secrets          | logo.png | banner.jpg | Mr Crab | Crusty crab         | [ABB169] Business | deletion_request | eInclusion    |
      | Teacher in the Twins     | The Guardian of the Stream | logo.png | banner.jpg | Mr Crab | Crusty crab         | [ABB169] Business | needs_update     | eInclusion    |
      | Missing Fire             | Flames in the Swords       | logo.png | banner.jpg | Mr Crab | Crusty crab         | [ABB169] Business | blacklisted      | eInclusion    |
    And the following solution user memberships:
      | solution        | user | roles |
      | Flight of Night | Hulk | owner |
    When I am logged in as a "facilitator" of the "Professional Dreams" solution
    And I go to the homepage of the "Professional Dreams" solution
    Then I should see the heading "Professional Dreams"
    And I should see the link "View draft"
    # @todo: Fix the visibility issue.
    But I should see the link "View"
    And I should see the link "Edit" in the "Entity actions" region

    # I should not be able to view draft solutions I'm not a facilitator of.
    When I go to the homepage of the "The Falling Swords" solution
    Then I should see the heading "Access denied"

    When I am logged in as a "facilitator" of the "Flight of Night" solution
    And I go to the homepage of the "Flight of Night" solution
    Then I should see the heading "Flight of Night"
    # Since it's validated, the normal view is the published view and the
    # "View draft" should not be shown.
    And I should not see the link "View Draft"

    # Edit as facilitator and save as draft.
    When I click "Edit"
    And I fill in "Title" with "Flight of Day"
    And I press "Save as draft"

    # The page redirects to the canonical view after editing.
    Then I should see the heading "Flight of Night"
    And I should not see the heading "Flight of Day"
    And I should see the link "View draft"
    When I click "View draft"
    # The header still shows the published title but the draft title is included
    # in the page.
    Then I should see the heading "Flight of Day"

    # Publish draft version of the solution.
    When I am logged in as a moderator
    And I go to the homepage of the "Flight of Day" solution
    And I click "Edit"
    And I press "Publish"
    Then I should see the heading "Flight of Day"
    And I should not see the link "View draft"
    But I should see the link "View"

    # Ensure that the users do not lose their membership.
    When I am logged in as "Hulk"
    And I go to the homepage of the "Flight of Day" solution
    Then I should not see the link "View Draft"
    But I should see the link "Edit" in the "Entity actions" region
