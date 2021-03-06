Feature: Manage relationships
  In order manage relationships
  As a user
  I want to list, view and edit relationships

  Background:
    And I have role "superuser"
    And I have a user "faimsadmin@intersect.org.au" with role "superuser"
    And I am logged in as "faimsadmin@intersect.org.au"
    And I have a project modules dir

#  @javascript
#  Scenario: Update relationship
#    Given I have project module "Sync Example"
#    And I am on the project modules page
#    And I follow "Sync Example"
#    And I follow "List Relationship Records"
#    And I press "Filter"
#    And I follow "AboveBelow 1"
#    And I update fields with values
#      | field    | type             | values                 |
#      | location | Constrained Data | Location A; Location C |
#      | name     | Annotation       | rel2                   |
#      | name     | Certainty        |                        |
#    And I refresh page
#    And I should see fields with values
#      | field    | type             | values                 |
#      | location | Constrained Data | Location A; Location C |
#      | name     | Annotation       | rel2                   |
#      | name     | Certainty        |                        |
#
#  @javascript
#  Scenario: Cannot update relationship if not member of module
#    Given I logout
#    And I have a user "other@intersect.org.au" with role "superuser"
#    And I am logged in as "other@intersect.org.au"
#    And I have project module "Sync Example"
#    And I am on the project modules page
#    And I follow "Sync Example"
#    And I follow "List Relationship Records"
#    And I press "Filter"
#    And I follow "AboveBelow 1"
#    And I update field "name" of type "Annotation" with values "test"
#    And I click on update for attribute with field "name"
#    Then I should see dialog "You are not a member of the module you are editing. Please ask a member to add you to the module before continuing."
#    And I confirm
#
#  @javascript
#  Scenario: Update relationship with hierarchical vocabulary
#    Given I have project module "Hierarchical Vocabulary"
#    And I am on the project modules page
#    And I follow "Hierarchical Vocabulary"
#    And I follow "List Relationship Records"
#    And I press "Filter"
#    And I follow "AboveBelow 2"
#    And I update fields with values
#      | field | type             | values                                       |
#      | type  | Constrained Data | Type A > Color A1 > Shape A1S1 > Size A1S1R3 |
#    And I refresh page
#    And I should see fields with values
#      | field | type             | values                                       |
#      | type  | Constrained Data | Type A > Color A1 > Shape A1S1 > Size A1S1R3 |
#
#  @javascript
#  Scenario: Update relationship attribute causes validation error
#    Given I have project module "Sync Example"
#    And I am on the project modules page
#    And I follow "Sync Example"
#    And I follow "Edit Module"
#    And I pick file "validation_schema.xml" for "Validation Schema"
#    And I press "Update"
#    Then I should see "Updated module"
#    And I follow "List Relationship Records"
#    And I press "Filter"
#    And I follow "AboveBelow 1"
#    And I update fields with values
#      | field | type       | values |
#      | name  | Annotation |        |
#    And I should see fields with errors
#      | field | error                |
#      | name  | Field value is blank |
#      | name  | Field value not text |
#
#  @javascript
#  Scenario: Cannot update relationship attribute if database is locked
#    Given I have project module "Sync Example"
#    And I am on the project modules page
#    And I follow "Sync Example"
#    And I follow "List Relationship Records"
#    And I press "Filter"
#    And I follow "AboveBelow 1"
#    And database is locked for "Sync Example"
#    And I update fields with values
#      | field    | type             | values                 |
#      | location | Constrained Data | Location A; Location C |
#    And I wait for popup to close
#    Then I should see dialog "Could not process request as project is currently locked."
#    And I confirm
#
#  # TODO Scenario: Update relationship attribute with multiple values causes validation error
#
#  Scenario: View relationship with attachments
#    Given I have project module "Sync Test"
#    And I am on the project modules page
#    And I click on "Sync Test"
#    Then I follow "Search Relationship Records"
#    And I enter "" and submit the form
#    And I select the first record
#    Then I should see attached files
#      | name                                   |
#      | Screenshot_2013-04-29-16-38-51.png     |
#      | Screenshot_2013-04-29-16-38-51 (1).png |
#    Then I remove all files for "Sync Test"
#
#  Scenario: View relationship with attachments which aren't synced
#    Given I have project module "Sync Test"
#    And I am on the project modules page
#    And I click on "Sync Test"
#    Then I follow "Search Relationship Records"
#    And I enter "" and submit the form
#    And I select the first record
#    Then I should see attached files
#      | name                                   |
#      | Screenshot_2013-04-29-16-38-51.png     |
#      | Screenshot_2013-04-29-16-38-51 (1).png |
#    Then I remove all files for "Sync Test"
#    Then I should see non attached files
#      | name                                   |
#      | Screenshot_2013-04-29-16-38-51.png     |
#      | Screenshot_2013-04-29-16-38-51 (1).png |
#
#  Scenario: View relationship list
#    Given I have project module "Sync Example"
#    And I am on the project modules page
#    And I follow "Sync Example"
#    Then I follow "Search Relationship Records"
#    And I enter "" and submit the form
#    Then I should see records
#      | name         |
#      | AboveBelow 1 |
#      | AboveBelow 2 |
#      | AboveBelow 3 |
#
#  @javascript
#  Scenario: View relationship list with deleted relationships
#    Given I have project module "Sync Example"
#    And I am on the project modules page
#    And I follow "Sync Example"
#    Then I follow "Search Relationship Records"
#    And I enter "" and submit the form
#    And I click on "Show Deleted"
#    Then I should see records
#      | name         |
#      | AboveBelow 1 |
#      | AboveBelow 2 |
#      | AboveBelow 3 |
#      | AboveBelow 4 |
#
#  @javascript
#  Scenario: Delete relationship
#    Given I have project module "Sync Example"
#    And I am on the project modules page
#    And I follow "Sync Example"
#    Then I follow "Search Relationship Records"
#    And I enter "" and submit the form
#    Then I follow "AboveBelow 2"
#    And I click on "Delete"
#    And I confirm
#    Then I should see "Deleted Relationship"
#    Then I should not see records
#      | name         |
#      | AboveBelow 2 |
#      | AboveBelow 4 |
#
#  @javascript
#  Scenario: Cannot delete relationship if database is locked
#    Given I have project module "Sync Example"
#    And I am on the project modules page
#    And I follow "Sync Example"
#    Then I follow "Search Relationship Records"
#    And I enter "" and submit the form
#    Then I follow "AboveBelow 2"
#    And database is locked for "Sync Example"
#    And I click on "Delete"
#    And I confirm
#    And I wait for page
#    Then I should see "Could not process request as project is currently locked."
#    And I follow "Back"
#    Then I should see records
#      | name         |
#      | AboveBelow 2 |
#
#  @javascript
#  Scenario: Cannot delete relationship if not member of module
#    Given I logout
#    And I have a user "other@intersect.org.au" with role "superuser"
#    And I am logged in as "other@intersect.org.au"
#    And I have project module "Sync Example"
#    And I am on the project modules page
#    And I follow "Sync Example"
#    Then I follow "Search Relationship Records"
#    And I enter "" and submit the form
#    Then I follow "AboveBelow 2"
#    And I click on "Delete"
#    And I confirm
#    Then I should see "You are not a member of the module you are editing. Please ask a member to add you to the module before continuing."
#    And I follow "Back"
#    Then I should see records
#      | name         |
#      | AboveBelow 2 |
#
#
#  @javascript
#  Scenario: Restore relationship
#    Given I have project module "Sync Example"
#    And I am on the project modules page
#    And I follow "Sync Example"
#    Then I follow "Search Relationship Records"
#    And I enter "" and submit the form
#    Then I follow "AboveBelow 2"
#    Then I click on "Delete"
#    And I confirm
#    Then I click on "Show Deleted"
#    Then I follow "AboveBelow 2"
#    Then I click on "Restore"
#    And I should see "Restored Relationship"
#    Then I follow "Back"
#    Then I click on "Hide Deleted"
#    And I should not see records
#      | name         |
#      | AboveBelow 4 |
#    But I should see records
#      | name         |
#      | AboveBelow 2 |
#
#  @javascript
#  Scenario: Cannot restore relationship if database is locked
#    Given I have project module "Sync Example"
#    And I am on the project modules page
#    And I follow "Sync Example"
#    Then I follow "Search Relationship Records"
#    And I enter "" and submit the form
#    Then I follow "AboveBelow 2"
#    Then I click on "Delete"
#    And I confirm
#    Then I click on "Show Deleted"
#    Then I follow "AboveBelow 2"
#    And database is locked for "Sync Example"
#    Then I click on "Restore"
#    And I wait for page
#    And I should see "Could not process request as project is currently locked."
#    Then I follow "Back"
#    Then I click on "Hide Deleted"
#    And I should not see records
#      | name         |
#      | AboveBelow 2 |
#      | AboveBelow 4 |
#
#  @javascript
#  Scenario: Cannot restore relationship if not member of module
#    Given I logout
#    And I have a user "other@intersect.org.au" with role "superuser"
#    And I am logged in as "other@intersect.org.au"
#    And I have project module "Sync Example"
#    And I am on the project modules page
#    And I follow "Sync Example"
#    Then I follow "Search Relationship Records"
#    And I enter "" and submit the form
#    Then I click on "Show Deleted"
#    Then I follow "AboveBelow 4"
#    Then I click on "Restore"
#    Then I should see "You are not a member of the module you are editing. Please ask a member to add you to the module before continuing."
#    Then I follow "Back"
#    Then I click on "Hide Deleted"
#    And I should not see records
#      | name         |
#      | AboveBelow 4 |