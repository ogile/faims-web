Feature: Manage project module users
  In order manage project module users
  As a user
  I want to list, view and edit project module users

  Background:
    And I have role "superuser"
    And I have a user "faimsadmin@intersect.org.au" with role "superuser"
    And I am logged in as "faimsadmin@intersect.org.au"
    And I have a project modules dir

  @javascript
  Scenario: Seeing users to be added for project module
    Given I have users
      | first_name | last_name | email                  |
      | User1      | Last1     | user1@intersect.org.au |
      | User2      | Last2     | user2@intersect.org.au |
    And I have project module "Module 1"
    Then I follow "Show Modules"
    And I should be on the project modules page
    And I follow "Module 1"
    Then I follow "Edit Users"
    And I should have user for selection
      | name        |
      | User1 Last1 |
      | User2 Last2 |

  @javascript
  Scenario: Adding users to the project module
    Given I have users
      | first_name | last_name | email                  |
      | User1      | Last1     | user1@intersect.org.au |
      | User2      | Last2     | user2@intersect.org.au |
    And I have project module "Module 1"
    And I add "faimsadmin@intersect.org.au" to "Module 1"
    Then I follow "Show Modules"
    And I should be on the project modules page
    And I follow "Module 1"
    Then I follow "Edit User"
    And I select "User1 Last1" from the user list
    Then I click on "Add"
    And I should see "Successfully updated user"
    And I should have user for project module
      | first_name | last_name |
      | Fred       | Bloggs    |
      | User1      | Last1     |

  @javascript
  Scenario: Cannot add user to project module if database is locked
    Given I have users
      | first_name | last_name | email                  |
      | User1      | Last1     | user1@intersect.org.au |
      | User2      | Last2     | user2@intersect.org.au |
    And I have project module "Module 1"
    And I add "faimsadmin@intersect.org.au" to "Module 1"
    Then I follow "Show Modules"
    And I should be on the project modules page
    And I follow "Module 1"
    Then I follow "Edit User"
    And database is locked for "Module 1"
    And I select "User1 Last1" from the user list
    Then I click on "Add"
    And I should see "Could not process request as database is currently locked"
    And I should have user for project module
      | first_name | last_name |
      | Fred       | Bloggs    |
    And I should not have user for project module
      | first_name | last_name |
      | User1      | Last1     |

  @javascript
  Scenario: Cannot add user to project module if user is not member of module
    Given I have users
      | first_name | last_name | email                  |
      | User1      | Last1     | user1@intersect.org.au |
      | User2      | Last2     | user2@intersect.org.au |
    And I logout
    And I have a user "other@intersect.org.au" with role "superuser"
    And I am logged in as "other@intersect.org.au"
    And I am on the home page
    And I have project module "Module 1"
    And I add "faimsadmin@intersect.org.au" to "Module 1"
    Then I follow "Show Modules"
    And I should be on the project modules page
    And I follow "Module 1"
    Then I follow "Edit User"
    And database is locked for "Module 1"
    And I select "User1 Last1" from the user list
    Then I click on "Add"
    Then I should see "Only module users can edit the database. Please get a module user to add you to the module"
    And I should have user for project module
      | first_name | last_name |
      | Fred       | Bloggs    |
    And I should not have user for project module
      | first_name | last_name |
      | User1      | Last1     |