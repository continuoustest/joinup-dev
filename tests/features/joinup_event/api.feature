@api
Feature: Event API
  In order to manage custom pages programmatically
  As a backend developer
  I need to be able to use the Node API to handle the "Event" bundle

  Scenario: Programmatically create an Event entity
    Given the following collection:
      | title             | Le Event Heureux |
      | owner             | Event Owner      |
      | logo              | logo.png         |
      | moderation        | yes              |
      | closed            | yes              |
      | elibrary creation | facilitators     |
    And event content:
      | title       | field_event_short_title | body                                     | collection       | field_start_date    |
      | Dummy Event | Short                   | This is some dummy content like foo:bar. | Le Event Heureux | 2016-03-15T11:12:12 |
    Then I should have a "Event" page titled "Dummy Event"