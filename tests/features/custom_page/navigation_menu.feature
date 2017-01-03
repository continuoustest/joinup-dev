@api
Feature: Navigation menu for custom pages
  In order to determine the order and visibility of custom pages in the navigation menu
  As a collection facilitator
  I need to be able to manage the navigation menu

  Scenario: Access the navigation menu through the contextual link
    Given the following collections:
      | title            | logo     | state     |
      | Rainbow tables   | logo.png | validated |
      | Cripple Mr Onion | logo.png | validated |

    # Initially there are no items in the navigation menu, instead we see a help
    # text inviting the user to add a page to the menu.
    When I am logged in as a facilitator of the "Rainbow tables" collection
    And I go to the homepage of the "Rainbow tables" collection
    Then the navigation menu of the "Rainbow tables" collection should have 0 visible items
    And I should see the text "There are no pages yet. Why don't you start by creating an About page?"
    And I should see the link "Add a new page"
    # Check that the 'Edit menu' local action is not present.
    But I should not see the contextual link "Edit menu" in the "Left sidebar" region
    # The 'Add link' local action that is present in the default implementation
    # of OG Menu should not be visible. We are managing the menu links behind
    # the scenes. The end user should not be able to interact with these.
    And I should not see the contextual link "Add link" in the "Left sidebar" region

    # When we create a custom page it should automatically show up in the menu.
    When I click "Add a new page"
    Then I should see the heading "Add custom page"
    When I fill in the following:
      | Title | About us              |
    And I enter "A short introduction." in the "Body" wysiwyg editor
    And I press "Save"
    Then I should see the success message "Custom page About us has been created."
    And the navigation menu of the "Rainbow tables" collection should have 1 visible item
    And I should not see the text "There are no custom pages yet."

    When I click the contextual link "Edit menu" in the "Left sidebar" region
    Then the navigation menu of the "Rainbow tables" collection should have 1 item
    But I should not see the text "There are no custom pages yet."

    # It should be possible to hide an item from the menu by disabling it.
    When I disable "About us" in the navigation menu of the "Rainbow tables" collection
    Then the navigation menu of the "Rainbow tables" collection should have 0 visible items

    # When all the pages are disabled in the navigation menu, a message should
    # be shown to the user.
    When I go to the homepage of the "Rainbow tables" collection
    Then I should see the text "All the pages have been disabled for this collection. You can edit the menu configuration or add a new page."
    And I should see the contextual link "Edit menu" in the "Left sidebar" region

    # The contextual menu can be used to navigate to the menu edit page.
    When I click the contextual link "Edit menu" in the "Left sidebar" region
    Then I should see the heading "Edit navigation menu of the Rainbow tables collection"

    # The form to add a new menu link should not be accessible by anyone. This
    # is functionality provided by Drupal which is intended for webmasters. We
    # are showing the menu overview to collection facilitators so they can
    # reorder the navigation menu, but they should not be able to access the
    # related menu administration screens.
    And I should not have access to the menu link administration pages for the navigation menu of the "Rainbow tables" collection

    # Enable the menu entry for the 'About us' page again so we can check if it
    # is visible for all users.
    When I enable "About us" in the navigation menu of the "Rainbow tables" collection

    # Create a few custom pages in the second collection so we can check if the
    # right menu shows up in each collection.
    Given custom_page content:
      | title           | body                                                                                                                                  | collection       |
      | Eights are wild | You cannot Cripple Mr Onion if your running flush contains more wild eights than the Lesser or Great Onion you are trying to cripple. | Cripple Mr Onion |
      | Eights are null | They can be included in an existing Onion in order to improve its size by one card.                                                   | Cripple Mr Onion |

    # Test as a normal member of the collection.
    Given I am logged in as a member of the "Rainbow tables" collection
    When I go to the homepage of the "Rainbow tables" collection
    # Members of the collection should not have access to the administration
    # pages.
    Then I should not have access to the menu link administration pages for the navigation menu of the "Rainbow tables" collection
    # The navigation link from the current collection should be visible, but not
    # the link from the second collection.
    And I should see the link "About us" in the "Navigation menu"
    But I should not see the link "Eights are wild" in the "Navigation menu"
    And I should not see the link "Eights are null" in the "Navigation menu"
    # Test the navigation link of the second collection.
    When I go to the homepage of the "Cripple Mr Onion" collection
    Then I should see the link "Eights are wild" in the "Navigation menu"
    And I should see the link "Eights are null" in the "Navigation menu"
    But I should not see the link "About us" in the "Navigation menu"

    # Test as a moderator.
    Given I am logged in as a moderator
    When I go to the homepage of the "Rainbow tables" collection
    # Even moderators should not have access to the administration pages.
    Then I should not have access to the menu link administration pages for the navigation menu of the "Rainbow tables" collection
    # The navigation link from the current collection should be visible, but not
    # the link from the second collection.
    And I should see the link "About us" in the "Navigation menu"
    But I should not see the link "Eights are wild" in the "Navigation menu"
    And I should not see the link "Eights are null" in the "Navigation menu"
    # Test the navigation link of the second collection.
    When I go to the homepage of the "Cripple Mr Onion" collection
    Then I should see the link "Eights are wild" in the "Navigation menu"
    And I should see the link "Eights are null" in the "Navigation menu"
    But I should not see the link "About us" in the "Navigation menu"

    # Test as an anonymous user.
    Given I am an anonymous user
    When I go to the homepage of the "Rainbow tables" collection
    # Anonymous users should definitely not have access to the administration
    # pages.
    Then I should not have access to the menu link administration pages for the navigation menu of the "Rainbow tables" collection
    # The navigation link from the current collection should be visible, but not
    # the link from the second collection.
    And I should see the link "About us" in the "Navigation menu"
    But I should not see the link "Eights are wild" in the "Navigation menu"
    And I should not see the link "Eights are null" in the "Navigation menu"
    # Test the navigation link of the second collection.
    When I go to the homepage of the "Cripple Mr Onion" collection
    Then I should see the link "Eights are wild" in the "Navigation menu"
    And I should see the link "Eights are null" in the "Navigation menu"
    But I should not see the link "About us" in the "Navigation menu"
