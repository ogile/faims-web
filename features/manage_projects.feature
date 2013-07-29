Feature: Manage projects
  In order manage projects
  As a user
  I want to list, create and edit projects

  Background:
    And I have role "superuser"
    And I have a user "georgina@intersect.org.au" with role "superuser"
    And I am on the login page
    And I am logged in as "georgina@intersect.org.au"
    And I should see "Logged in successfully."
    And I have a projects dir

  Scenario: List projects
    Given I am on the home page
    And I have projects
      | name      |
      | Project 1 |
      | Project 2 |
      | Project 3 |
    And I follow "Show Projects"
    Then I should see projects
      | name      |
      | Project 1 |
      | Project 2 |
      | Project 3 |

  Scenario: Create a new project
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I follow "Create Project"
    Then I should be on the new projects page
    And I fill in "Name" with "Project 1"
    And I pick file "data_schema.xml" for "Data Schema"
    And I pick file "ui_schema.xml" for "UI Schema"
    And I pick file "validation_schema.xml" for "Validation Schema"
    And I pick file "ui_logic.bsh" for "UI Logic"
    And I pick file "faims_Project_1.properties" for "Arch16n"
    And I press "Submit"
    Then I should see "New project created."
    And I should be on the projects page
    And I have project files for "Project 1"

  Scenario: Optional validation schema
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I follow "Create Project"
    Then I should be on the new projects page
    And I fill in "Name" with "Project 1"
    And I pick file "data_schema.xml" for "Data Schema"
    And I pick file "ui_schema.xml" for "UI Schema"
    And I pick file "ui_logic.bsh" for "UI Logic"
    And I pick file "faims_Project_1.properties" for "Arch16n"
    And I press "Submit"
    Then I should see "New project created."
    And I should be on the projects page
    And I have project files for "Project 1"

  Scenario: Set srid on project creation
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I follow "Create Project"
    Then I should be on the new projects page
    And I fill in "Name" with "Project 1"
    And I fill in "Project SRID" with "EPSG:4326 - WGS 84"
    And I pick file "data_schema.xml" for "Data Schema"
    And I pick file "ui_schema.xml" for "UI Schema"
    And I pick file "validation_schema.xml" for "Validation Schema"
    And I pick file "ui_logic.bsh" for "UI Logic"
    And I pick file "faims_Project_1.properties" for "Arch16n"
    And I press "Submit"
    Then I should see "New project created."
    And I should be on the projects page
    And I have project files for "Project 1"
    And I should have setting "srid" for "Project 1" as "4326"

  Scenario Outline: Cannot create project due to errors
    Given I am on the home page
    And I have project "Project 1"
    And I follow "Show Projects"
    Then I should be on the projects page
    And I follow "Create Project"
    Then I should be on the new projects page
    And I fill in "<field>" with "<value>"
    And I press "Submit"
    Then I should see "<field>" with error "<error>"
  Examples:
    | field       | value     | error          |
    | Name        |           | can't be blank |
    | Name        | Project * | is invalid     |
    | Data Schema |           | can't be blank |
    | UI Schema   |           | can't be blank |
    | UI Logic    |           | can't be blank |

  Scenario Outline: Cannot create project due to errors
    Given I am on the home page
    And I have project "Project 1"
    And I follow "Show Projects"
    Then I should be on the projects page
    And I follow "Create Project"
    Then I should be on the new projects page
    And I wait
    And I fill in "Project Name" with "Project 2"
    And I wait
    And I pick file "<value>" for "<field>"
    And I press "Submit"
    Then I should see "<field>" with error "<error>"
  Examples:
    | field       | value                      | error                   |
    | Data Schema |                            | can't be blank          |
    | Data Schema | garbage                    | must be xml file        |
    | Data Schema | data_schema_error1.xml     | invalid xml at line   |
    | UI Schema   |                            | can't be blank          |
    | UI Schema   | garbage                    | must be xml file        |
    | UI Schema   | ui_schema_error1.xml       | invalid xml at line      |
    | Validation Schema   | garbage                | must be xml file       |
    | Validation Schema   | data_schema_error1.xml | invalid xml at line  |
    | UI Logic    |                            | can't be blank          |
    | Arch16n     | faims_error.properties     | invalid file name       |
    | Arch16n     | faims_Project_2.properties | invalid properties file at line |

  Scenario: Upload Project
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "project.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "Project has been successfully uploaded"
    And I should be on the projects page
    And I have project files for "Simple Project"

  Scenario: Upload Project if project already exists should fail
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "project.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "Project has been successfully uploaded"
    And I follow "Upload Project"
    And I pick file "project.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "This project already exists in the system"

  Scenario: Upload Project with wrong checksum should fail
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "project_corrupted1.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "Wrong hash sum for the project"

  Scenario: Upload Project with corrupted file should fail
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "project_corrupted2.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "Project failed to upload"

  Scenario: Upload Project with wrong file should fail
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "project.tar" for "Project File"
    And I press "Upload"
    Then I should see "Project failed to upload"

  Scenario Outline: Edit static data
    Given I am on the home page
    And I have project "Project 1"
    And I follow "Show Projects"
    Then I should be on the projects page
    And I click on "Project 1"
    Then I follow "Edit Project"
    And I fill in "<field>" with "<value>"
    And I press "Update"
    And I should have setting "<setting>" for "Project 1" as "<setting_value>"
  Examples:
    | field        | value     | setting | setting_value |
    | Project SRID | EPSG:4326 - WGS 84          | srid | 4326 |

  Scenario Outline: Edit static data fails with errors
    Given I am on the home page
    And I have project "Project 1"
    And I follow "Show Projects"
    Then I should be on the projects page
    And I click on "Project 1"
    Then I follow "Edit Project"
    And I fill in "<field>" with "<value>"
    And I press "Update"
    Then I should see "<field>" with error "<error>"
  Examples:
    | field        | value     | error          |
    | Project Name |           | can't be blank |
    | Project Name | Project * | is invalid     |

  Scenario:  Edit project but not upload new file
    Given I am on the home page
    And I have project "Project 1"
    And I follow "Show Projects"
    Then I should be on the projects page
    And I click on "Project 1"
    Then I follow "Edit Project"
    And I press "Update"
    Then I should see "Successfully updated project"

  Scenario: Edit project and upload correct file
    Given I am on the home page
    And I have project "Project 1"
    And I follow "Show Projects"
    Then I should be on the projects page
    And I click on "Project 1"
    Then I follow "Edit Project"
    And I pick file "ui_schema.xml" for "UI Schema"
    And I pick file "validation_schema.xml" for "Validation Schema"
    And I pick file "ui_logic.bsh" for "UI Logic"
    And I pick file "faims_Project_1.properties" for "Arch16n"
    And I press "Update"
    Then I should see "Successfully updated project"

  Scenario: Edit project and upload correct file so project has correct file
    Given I am on the home page
    And I have project "Project 1"
    And I follow "Show Projects"
    Then I should be on the projects page
    And I click on "Project 1"
    Then I follow "Edit Project"
    And I pick file "faims_Project_1.properties" for "Arch16n"
    And I press "Update"
    Then I should see "Successfully updated project"
    And Project "Project 1" should have the same file "faims_Project_1.properties"

  Scenario Outline: Edit project and upload incorrect file
    Given I am on the home page
    And I have project "Project 2"
    And I follow "Show Projects"
    Then I should be on the projects page
    And I click on "Project 2"
    And I wait
    Then I follow "Edit Project"
    And I wait
    And I pick file "<value>" for "<field>"
    And I wait
    And I press "Update"
    Then I should see "<field>" with error "<error>"
  Examples:
    | field       | value                      | error                   |
    | UI Schema   | garbage                    | must be xml file        |
    | UI Schema   | ui_schema_error1.xml       | invalid xml at line   |
    | Validation Schema   | garbage                | must be xml file    |
    | Validation Schema   | data_schema_error1.xml | invalid xml at line |
    | Arch16n     | faims_error.properties     | invalid file name       |
    | Arch16n     | faims_Project_2.properties | invalid properties file at line|

  Scenario: Pull a list of projects
    Given I have projects
      | name      |
      | Project 1 |
      | Project 2 |
      | Project 3 |
    And I am on the android projects page
    Then I should see json for projects

  Scenario: Download package
    Given I have project "Project 1"
    And I follow "Show Projects"
    Then I should be on the projects page
    And I click on "Project 1"
    And I follow "Download Project"
    Then I automatically archive project package "Project 1"
    Then I automatically download project package "Project 1"
    Then I should download project package file for "Project 1"

  Scenario: See attached files for arch ent
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "Sync_Test.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "Project has been successfully uploaded"
    And I should be on the projects page
    And I click on "Sync Test"
    Then I follow "Search Archaeological Entity Records"
    And I enter "" and submit the form
    And I select the first record
    Then I should see attached files
      | name                                  |
      | Screenshot_2013-04-09-10-32-04.png    |
      | Screenshot_2013-04-09-10-32-04(1).png |

#  @javascript
#  Scenario: Download attached file for arch ent
#    Given I am on the home page
#    And I follow "Show Projects"
#    Then I should be on the projects page
#    And I wait
#    And I follow "Upload Project"
#    And I pick file "Sync_Test.tar.bz2" for "Project File"
#    And I press "Upload"
#    Then I should see "Project has been successfully uploaded"
#    And I should be on the projects page
#    And I click on "Sync Test"
#    Then I follow "Search Archaeological Entity Records"
#    And I enter "" and submit the form
#    And I select the first record
#    Then I click file with name "Screenshot_2013-04-09-10-32-04(1).png"
#    And I should download attached file with name "Screenshot_2013-04-09-10-32-04(1).png"

  Scenario: See attached files for relationship
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "Sync_Test.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "Project has been successfully uploaded"
    And I should be on the projects page
    And I click on "Sync Test"
    And I wait
    Then I follow "Search Relationship Records"
    And I enter "" and submit the form
    And I select the first record
    Then I should see attached files
      | name                                  |
      | Screenshot_2013-04-29-16-38-51.png    |
      | Screenshot_2013-04-29-16-38-51(1).png |

#  @javascript
#  Scenario: Download attached file for relationship
#    Given I am on the home page
#    And I follow "Show Projects"
#    Then I should be on the projects page
#    And I wait
#    And I follow "Upload Project"
#    And I pick file "Sync_Test.tar.bz2" for "Project File"
#    And I press "Upload"
#    Then I should see "Project has been successfully uploaded"
#    And I should be on the projects page
#    And I click on "Sync Test"
#    Then I follow "Search Relationship Records"
#    And I enter "" and submit the form
#    And I select the first record
#    Then I click file with name "Screenshot_2013-04-29-16-38-51(1).png"
#    And I should download attached file with name "Screenshot_2013-04-29-16-38-51(1).png"

  @javascript
  Scenario: View Vocabularies
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I follow "Create Project"
    Then I should be on the new projects page
    And I fill in "Name" with "Project 1"
    And I pick file "data_schema.xml" for "Data Schema"
    And I pick file "ui_schema.xml" for "UI Schema"
    And I pick file "validation_schema.xml" for "Validation Schema"
    And I pick file "ui_logic.bsh" for "UI Logic"
    And I pick file "faims_Project_1.properties" for "Arch16n"
    And I press "Submit"
    Then I should see "New project created."
    And I should be on the projects page
    And I click on "Project 1"
    And I wait
    Then I follow "Edit Vocabulary"
    And I select "Soil Texture" for the attribute
    Then I should see vocabularies
    | name  |
    | Green |
    | Pink  |
    | Blue  |

  @javascript
  Scenario: Update Vocabulary
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I follow "Create Project"
    Then I should be on the new projects page
    And I fill in "Name" with "Project 1"
    And I pick file "data_schema.xml" for "Data Schema"
    And I pick file "ui_schema.xml" for "UI Schema"
    And I pick file "validation_schema.xml" for "Validation Schema"
    And I pick file "ui_logic.bsh" for "UI Logic"
    And I pick file "faims_Project_1.properties" for "Arch16n"
    And I press "Submit"
    Then I should see "New project created."
    And I should be on the projects page
    And I click on "Project 1"
    Then I click on "Edit Vocabulary"
    And I select "Soil Texture" for the attribute
    And I modify vocabulary "Green" with "Red"
    Then I follow "Update"
    And I should see "Successfully updated vocabulary"
    And I should see vocabularies
      | name  |
      | Red   |
      | Pink  |
      | Blue  |

  @javascript
  Scenario: Insert Vocabulary
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I follow "Create Project"
    Then I should be on the new projects page
    And I wait
    And I fill in "Name" with "Project 1"
    And I pick file "data_schema.xml" for "Data Schema"
    And I pick file "ui_schema.xml" for "UI Schema"
    And I pick file "validation_schema.xml" for "Validation Schema"
    And I pick file "ui_logic.bsh" for "UI Logic"
    And I pick file "faims_Project_1.properties" for "Arch16n"
    And I press "Submit"
    Then I should see "New project created."
    And I should be on the projects page
    And I click on "Project 1"
    And I wait
    Then I follow "Edit Vocabulary"
    And I select "Soil Texture" for the attribute
    And I wait
    Then I follow "Insert"
    And I wait
    And I add "Red" to the vobulary list
    Then I follow "Update"
    And I should see "Successfully updated vocabulary"
    And I should see vocabularies
      | name  |
      | Green |
      | Red   |
      | Pink  |
      | Blue  |

  @javascript
  Scenario: Seeing users to be added for project
    Given I have users
      | first_name | last_name | email                  |
      | User1      | Last1     | user1@intersect.org.au |
      | User2      | Last2     | user2@intersect.org.au |
    And I have project "Project 1"
    Then I follow "Show Projects"
    And I should be on the projects page
    And I click on "Project 1"
    And I wait
    Then I follow "Edit User"
    And I should have user for selection
      | name        |
      | User1 Last1 |
      | User2 Last2 |


  @javascript
  Scenario: Adding users to the project
    Given I have users
      | first_name | last_name | email                  |
      | User1      | Last1     | user1@intersect.org.au |
      | User2      | Last2     | user2@intersect.org.au |
    And I have project "Project 1"
    Then I follow "Show Projects"
    And I should be on the projects page
    And I click on "Project 1"
    And I wait
    Then I follow "Edit User"
    And I select "User1 Last1" from the user list
    Then I follow "Add"
    And I should see "Successfully updated user"
    And I should have user for project
      | first_name | last_name |
      | Fred       | Bloggs     |
      | User1      | Last1     |

  Scenario: Show arch entity list not include the deleted value
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "Sync_Example.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "Project has been successfully uploaded"
    And I should be on the projects page
    And I click on "Sync Example"
    And I wait
    Then I follow "Search Archaeological Entity Records"
    And I enter "" and submit the form
    Then I should see records
      | name            |
      | entity: Small 2 |
      | entity: Small 3 |
      | entity: Small 4 |

  @javascript
  Scenario: Show arch entity list include the deleted value
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "Sync_Example.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "Project has been successfully uploaded"
    And I should be on the projects page
    And I click on "Sync Example"
    And I wait
    Then I follow "Search Archaeological Entity Records"
    And I enter "" and submit the form
    And I follow "Show Deleted"
    Then I should see records
      | name            |
      | entity: Small 1 |
      | entity: Small 2 |
      | entity: Small 3 |
      | entity: Small 4 |

  Scenario: Delete arch entity
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "Sync_Example.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "Project has been successfully uploaded"
    And I should be on the projects page
    And I click on "Sync Example"
    And I wait
    Then I follow "Search Archaeological Entity Records"
    And I enter "" and submit the form
    Then I select the first record
    And I follow "Delete"
    Then I should not see records
      | name            |
      | entity: Small 1 |
      | entity: Small 3 |

  @javascript
  Scenario: Restore arch entity
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "Sync_Example.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "Project has been successfully uploaded"
    And I should be on the projects page
    And I click on "Sync Example"
    And I wait
    Then I follow "Search Archaeological Entity Records"
    And I enter "" and submit the form
    Then I select the first record
    And I wait
    Then I follow "Delete"
    And I wait
    Then I follow "Show Deleted"
    And I wait
    Then I select the first record
    And I wait
    Then I follow "Restore"
    And I should see "Successfully restored archaeological entity record"
    Then I follow "Back"
    And I wait
    Then I follow "Hide Deleted"
    And I should not see records
      | name            |
      | entity: Small 1 |
    But I should see records
      | name            |
      | entity: Small 3 |

  Scenario: Show relationship list not include the deleted value
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "Sync_Example.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "Project has been successfully uploaded"
    And I should be on the projects page
    And I click on "Sync Example"
    And I wait
    Then I follow "Search Relationship Records"
    And I enter "" and submit the form
    Then I should see records
      | name                        |
      | relationship: AboveBelow 1  |
      | relationship: AboveBelow 2  |
      | relationship: AboveBelow 3  |

  @javascript
  Scenario: Show relationship list include the deleted value
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "Sync_Example.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "Project has been successfully uploaded"
    And I should be on the projects page
    And I click on "Sync Example"
    And I wait
    Then I follow "Search Relationship Records"
    And I enter "" and submit the form
    And I follow "Show Deleted"
    Then I should see records
      | name                        |
      | relationship: AboveBelow 1  |
      | relationship: AboveBelow 2  |
      | relationship: AboveBelow 3  |
      | relationship: AboveBelow 4  |

  Scenario: Delete relationship
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "Sync_Example.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "Project has been successfully uploaded"
    And I should be on the projects page
    And I click on "Sync Example"
    And I wait
    Then I follow "Search Relationship Records"
    And I enter "" and submit the form
    Then I select the first record
    And I follow "Delete"
    Then I should not see records
      | name            |
      | relationship: AboveBelow 2  |
      | relationship: AboveBelow 4  |

  @javascript
  Scenario: Restore relationship
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "Sync_Example.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "Project has been successfully uploaded"
    And I should be on the projects page
    And I click on "Sync Example"
    And I wait
    Then I follow "Search Relationship Records"
    And I enter "" and submit the form
    Then I select the first record
    And I wait
    Then I follow "Delete"
    And I wait
    Then I follow "Show Deleted"
    And I wait
    Then I select the first record
    And I wait
    Then I follow "Restore"
    And I should see "Successfully restored relationship record"
    Then I follow "Back"
    And I wait
    Then I follow "Hide Deleted"
    And I should not see records
      | name                        |
      | relationship: AboveBelow 4  |
    But I should see records
      | name            |
      | relationship: AboveBelow 2  |

  Scenario: See related arch entities
    Given I am on the home page
    And I follow "Show Projects"
    Then I should be on the projects page
    And I wait
    And I follow "Upload Project"
    And I pick file "Sync_Example.tar.bz2" for "Project File"
    And I press "Upload"
    Then I should see "Project has been successfully uploaded"
    And I should be on the projects page
    And I click on "Sync Example"
    And I wait
    Then I follow "Search Archaeological Entity Records"
    And I enter "" and submit the form
    Then I follow "entity: Small 2"
    And I wait
    Then I follow "small Below AboveBelow: Small 3"
    And I wait
    Then I follow "Back"
    And I should see related arch entities
      | name                            |
      | small Below AboveBelow: Small 3 |
      | small Below AboveBelow: Small 4 |

  Scenario: Update arch entity attribute causes validation error    s
    # TODO

  Scenario: Update arch entity attribute clears validation error
    # TODO

  Scenario: Update arch entity attribute with multiple values causes validation error
    # TODO

  Scenario: Update arch entity attribute with multiple values clears validation error
    # TODO

  Scenario: Show arch entity with validation errors as dirty
    # TODO

  Scenario: Show arch entity with validation errors as normal after validation errors cleared
    # TODO

  Scenario: Update relationship attribute causes validation error
    # TODO

  Scenario: Update relationship attribute clears validation error
    # TODO

  Scenario: Update relationship attribute with multiple values causes validation error
    # TODO

  Scenario: Update relationship attribute with multiple values clears validation error
    # TODO

  Scenario: Show relationship with validation errors as dirty
    # TODO

  Scenario: Show relationship with validation errors as normal after validation errors cleared
    # TODO

  Scenario: Show relationship association for arch ent
    # TODO

  Scenario: Remove relationship association from arch ent
    # TODO

  Scenario: Add relationship association to arch ent
    # TODO

  Scenario: Show arch ent member for relationship
    # TODO

  Scenario: Remove arch ent member from relationship
    # TODO

  Scenario: Add arch ent member to relationship
    # TODO