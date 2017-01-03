@api
Feature: Collection moderation
  In order to manage collections programmatically
  As a user of the website
  I need to be able to transit the collections from one state to another.

  # Access checks are not being made here. They are run in the collection add feature.
  Scenario: 'Draft' and 'Propose' states are available but moderators should also see 'Validated' state.
    When I am logged in as an "authenticated user"
    And I go to the homepage
    And I click "Propose collection"
    Then the following buttons should be present "Save as draft, Propose"
    And the following buttons should not be present "Publish, Request archival, Request deletion, Archive"

    When I am logged in as a user with the "moderator" role
    And I go to the homepage
    And I click "Propose collection"
    Then the following buttons should be present "Save as draft, Propose, Publish"
    And the following buttons should not be present "Request archival, Request deletion, Archive"

  Scenario: Test the moderation workflow available states.
    Given the following owner:
      | name           |
      | Simon Sandoval |
    And the following contact:
      | name  | Francis             |
      | email | Francis@example.com |
    And users:
      | name            | roles     |
      # Authenticated user.
      | Velma Smith     |           |
      # Moderator.
      | Lena Richardson | moderator |
      # Owner of all the collections.
      | Erika Reid      |           |
      # Facilitator of all the collections.
      | Carole James    |           |
    And the following collections:
      | title                   | description             | logo     | banner     | owner          | contact information | state            |
      | Deep Past               | Azure ship              | logo.png | banner.jpg | Simon Sandoval | Francis             | draft            |
      | The Licking Silence     | The Licking Silence     | logo.png | banner.jpg | Simon Sandoval | Francis             | proposed         |
      | Person of Wizards       | Person of Wizards       | logo.png | banner.jpg | Simon Sandoval | Francis             | validated        |
      | The Shard's Hunter      | The Shard's Hunter      | logo.png | banner.jpg | Simon Sandoval | Francis             | archival_request |
      | The Dreams of the Mists | The Dreams of the Mists | logo.png | banner.jpg | Simon Sandoval | Francis             | deletion_request |
      | Luck in the Abyss       | Luck in the Abyss       | logo.png | banner.jpg | Simon Sandoval | Francis             | archived         |
    And the following collection user memberships:
      | collection              | user         | roles       |
      | Deep Past               | Erika Reid   | owner       |
      | The Licking Silence     | Erika Reid   | owner       |
      | Person of Wizards       | Erika Reid   | owner       |
      | The Shard's Hunter      | Erika Reid   | owner       |
      | The Dreams of the Mists | Erika Reid   | owner       |
      | Luck in the Abyss       | Erika Reid   | owner       |
      | Deep Past               | Carole James | facilitator |
      | The Licking Silence     | Carole James | facilitator |
      | Person of Wizards       | Carole James | facilitator |
      | The Shard's Hunter      | Carole James | facilitator |
      | The Dreams of the Mists | Carole James | facilitator |
      | Luck in the Abyss       | Carole James | facilitator |

    # The following table tests the allowed transitions in a collection.
    # For each entry, the following steps must be performed:
    # Login with the given user (or a user with the same permissions).
    # Go to the homepage of the given collection.
    # If the expected states (states column) are empty, I should not have access
    # to the edit screen.
    # If the expected states are not empty, then I see the "Edit" link.
    # When I click the "Edit" link
    # Then the state field should have only the given states available.
    Then for the following collection, the corresponding user should have the corresponding available state buttons:
      | collection              | user            | states                                                     |

      # The owner is also a facilitator so the only
      # UATable part of the owner is that he has the ability to request deletion
      # or archival when the collection is validated.
      | Deep Past               | Erika Reid      | Save as draft, Propose                                     |
      | The Licking Silence     | Erika Reid      | Save as draft, Propose                                     |
      | Person of Wizards       | Erika Reid      | Save as draft, Propose, Request archival, Request deletion |
      | The Shard's Hunter      | Erika Reid      |                                                            |
      | The Dreams of the Mists | Erika Reid      |                                                            |
      | Luck in the Abyss       | Erika Reid      |                                                            |

      # The following collections do not follow the rule above and should be
      # testes as shown.
      | Deep Past               | Carole James    | Save as draft, Propose                                     |
      | The Licking Silence     | Carole James    | Save as draft, Propose                                     |
      | Person of Wizards       | Carole James    | Save as draft, Propose                                     |
      | The Shard's Hunter      | Carole James    |                                                            |
      | The Dreams of the Mists | Carole James    |                                                            |
      | Luck in the Abyss       | Carole James    |                                                            |
      | Deep Past               | Velma Smith     |                                                            |
      | The Licking Silence     | Velma Smith     |                                                            |
      | Person of Wizards       | Velma Smith     |                                                            |
      | The Shard's Hunter      | Velma Smith     |                                                            |
      | The Dreams of the Mists | Velma Smith     |                                                            |
      | Luck in the Abyss       | Velma Smith     |                                                            |
      | Deep Past               | Lena Richardson | Save as draft, Propose, Publish                            |
      | The Licking Silence     | Lena Richardson | Save as draft, Propose, Publish                            |
      | Person of Wizards       | Lena Richardson | Save as draft, Propose, Publish                            |
      | The Shard's Hunter      | Lena Richardson | Publish, Archive                                           |
      | The Dreams of the Mists | Lena Richardson | Publish                                                    |
      | Luck in the Abyss       | Lena Richardson |                                                            |

    # Authentication sample checks.
    Given I am logged in as "Carole James"

    # Expected access.
    And I go to the "Deep Past" collection
    Then I should see the link "Edit"
    When I click "Edit"
    Then I should not see the heading "Access denied"
    And the following buttons should be present "Save as draft, Propose"
    And the following buttons should not be present "Publish, Request archival, Request deletion, Archive"

    # Expected access.
    When I go to the "The Licking Silence" collection
    Then I should see the link "Edit"
    When I click "Edit"
    Then I should not see the heading "Access denied"
    And the following buttons should be present "Save as draft, Propose"
    And the following buttons should not be present "Publish, Request archival, Request deletion, Archive"

    # One check for the moderator.
    Given I am logged in as "Lena Richardson"
    # Expected access.
    And I go to the "Deep Past" collection
    Then I should see the link "Edit"
    When I click "Edit"
    Then I should not see the heading "Access denied"
    And the following buttons should be present "Save as draft, Propose, Publish"
    And the following buttons should not be present "Request archival, Request deletion, Archive"

  Scenario: Published collections should be shown in the collections overview page.
    # Regression test for ticket ISAICP-2889.
    Given the following owner:
      | name             | type    |
      | Carpet Sandation | Company |
    And the following contact:
      | name  | Partyanimal             |
      | email | partyanmial@example.com |
    And collection:
      | title               | Some berry pie     |
      | description         | Berries are tasty. |
      | logo                | logo.png           |
      | banner              | banner.jpg         |
      | owner               | Carpet Sandation   |
      | contact information | Partyanimal        |
      | policy domain       | eProcurement       |
      | state               | proposed           |
    When I am on the homepage
    And I click "Collections"
    Then I should not see the heading "Some berry pie"
    When I am logged in as a moderator
    And I am on the homepage
    # @todo Remove this line when caching Search API results is fixed.
    # @see https://webgate.ec.europa.eu/CITnet/jira/browse/ISAICP-2574
    And the cache has been cleared
    And I click "Collections"
    # Tile view modes in the "Collections" page are not using heading markup
    # for titles.
    Then I should see the text "Some berry pie"
    When I go to the homepage of the "Some berry pie" collection
    And I click "Edit"
    And I fill in "Title" with "No berry pie"
    And I press "Publish"
    Then I should see the heading "No berry pie"

    When I am on the homepage
    # @todo Remove this line when caching Search API results is fixed.
    # @see https://webgate.ec.europa.eu/CITnet/jira/browse/ISAICP-2574
    And the cache has been cleared
    And I click "Collections"
    Then I should see the text "No berry pie"
    And I should not see the text "Some berry pie"
