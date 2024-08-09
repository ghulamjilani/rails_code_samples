# Rails Code Samples
I have structured this repository for introductory or reference purpose regarding my code samples. Here is the structure of the repo:

~~~
/rails_code_samples
│
├── /controllers                        # Controller files
│   ├── communities_controller.rb
│   ├── courses_controller.rb                      
│   ├── madrassas_controller.rb                                   
│   └── messages_controller.rb         
│
├── /helpers                            # Helper files
│   ├── conversation_helper.rb                      
│   ├── students_helper.rb                                   
│   └── user_helper.rb               
│
├── /javascript                         # JS files containing stimulus logic
│   ├── address_controller.js
│   ├── managers_controller.js                      
│   ├── scores_controller.js                                     
│   └── validation_controller.js             
│
├── /models                             # Model files
│   ├── ability.rb                      
│   ├── company.rb
│   ├── course.rb
│   ├── event.rb                        
│   └── student.rb                       
│
├── /services                           # Service files
│   ├── address_service.rb
│   ├── generate_qr_service.rb
│   ├── pay_installment.rb               
│   └── verify.rb                        
│
├── /stylesheets                        # CSS / SCSS files
│   ├── add_session.scss
│   ├── avatar.scss     
│   └── navbar_menu.scss
│
├── /views                              # View files
│   ├── _student_marks_form.html.erb
│   ├── madrassa_list.html.erb     
│   └── student_listing.html.erb         
│
└── README.md                           # Project documentation
~~~

### Controllers

---
#### CommunitiesController
This controller class is managing community-related features such as event and webinar organization, member management, and document handling. The controller leverages various modules and concerns to streamline functionalities, including user authentication, role-based access control, and content management. Key features include importing members, handling community requests and invitations, and managing community-specific events and webinars.

#### CoursesController
The CoursesController is a meticulously crafted component of our API, ensuring secure and efficient management of course data. With robust authentication, comprehensive error handling, and optimized data rendering, it provides a seamless experience for both users and developers. This controller exemplifies best practices in clean code and modular architecture, ensuring scalability and maintainability for future growth.

#### MadrassasController
The MadrassasController efficiently manages madrassa data with a focus on secure access control and user-specific data filtering. It features actions for creating, updating, and deleting madrassas, with robust error handling and user-friendly feedback. The controller also provides specialized endpoints for retrieving madrassas based on region and listing classes within a madrassa, ensuring a tailored experience for `different user roles`.

#### MessagesController
This controller class handles the creation, editing, and deletion of messages within conversations. It ensures user authentication and manages conversation contexts, facilitating message interactions between users. Key actions include creating new messages, editing existing ones, and loading messages for various views.

### Helpers

---
#### ConversationsHelper
The ConversationHelper module provides various helper methods for handling conversation-related functionalities. It includes methods for displaying conversation pictures, names, and other user IDs, as well as `formatting` last messages and dates. Additionally, it offers utility functions for generating group management URLs, file links, and displaying conversation creator information.

#### StudentsHelper
The StudentsHelper module enhances the madrassa system by providing essential methods for managing student data and interactions. It offers `utility functions` for generating option lists and dynamically rendering form fields based on the student's subject. Additionally, it includes methods for displaying feedback options and integrates with Stimulus controllers to support responsive and interactive form elements. This helper ensures a streamlined, user-friendly experience for both teachers and students, making it easier to manage and update student information.

#### UserHelper
This module provides utility methods for user pictures, date formatting, video embeds, and privacy settings. It follows best practices for user interactions, connection statuses, and research management, ensuring `clean and efficient code`.

### Javascript

---
I will be covering Stimulus in this directory, as it is the default JavaScript framework in Rails 7.
#### AddressController
This `Stimulus controller` manages address dropdowns by updating them based on postcode input and API responses. It initializes dropdowns conditionally, handles API errors gracefully, and maintains user feedback through `validation` classes. Designed with `best practices` for maintainability and efficiency.

#### ManagersController
This `Stimulus controller` enhances file input fields with image preview functionality. It listens for file changes to display selected images and manages the visibility of preview elements. On initialization, it shows existing images if available and hides placeholder elements. This ensures a seamless `user experience` when interacting with file uploads.

#### ScoresController
This `Stimulus controller` manages `dynamic form updates` for different subjects. It handles the display and input of specific fields based on the selected subject, ensuring that previously selected values are preserved and updated correctly. The controller also includes functionality to toggle additional feedback fields based on user selection.

#### ValidationController
This `Stimulus controller` handles form validation by toggling required field checks and button states. It enables validators on form input elements when connected and disables them when disconnected. The controller updates button styling and enables/disables form submission based on whether all required fields are filled.

### Models

---
#### Ability
The Ability class defines user permissions and access control within the application using CanCanCan. It assigns different levels of access based on user roles—Super Admin, Regional Admin, Head Teacher, and Teacher—ensuring that each user can perform actions relevant to their responsibilities. Super Admins have unrestricted access, while other roles have scoped `permissions` based on their associated region, madrassa, and `role-specific limitations`.

#### Company
The Company model class includes features such as image and video management, relationship handling, and data validation. It supports friendly URLs with friendly_id, manages attachments and media files, and integrates with other models like User, Picture, Announcement, and Event. It also provides scopes for filtering and viewing, and includes methods for managing user roles and media presence validations.

#### Course
This model class represents a course with various associations and functionalities. It supports attachments for images and registration forms, manages course registrations and user schedules, and tracks activities and attendances. Key features include `scope-based` queries for visibility and publication, validation for course names, and methods to determine user registration status and course progress. `Notifications` are sent to employees upon course creation, and the model also provides methods to fetch URLs for attachments and to determine the current stage of a user's progress in the course.

#### Event
The model class manages event details and interactions, supporting various types and statuses. It integrates with FriendlyId for URL slugs and PaperTrail for version tracking. The model includes scopes for filtering by type, date, and status, and associations with Picture, Video, and RSVP statuses. It also features methods for searching, handling event dates, and listing attendees.

#### Student
This model class manages student data with best practices, including efficient associations, validations for essential attributes, and scopes for flexible querying. It leverages Active Storage for image uploads and integrates with S3 for secure file handling. Callbacks are used for managing related records and sending notifications, ensuring robust data integrity and automated updates.

### Services

---
#### AddressService
This class manages API requests to retrieve address data based on a postcode. It encapsulates API logic within a service object, ensuring separation of concerns. It uses environment variables for secure configuration of API URLs and tokens. The class handles errors by logging response issues, and parses the API response to construct and return complete address strings. This approach promotes secure, maintainable, and well-structured code.

#### GenerateQrService
This class generates a `QR code` for a given user, linking to their profile page. It utilizes `rqrcode` to create the QR code and `ActiveStorage` to handle file storage. The generated QR code is saved as a PNG file and attached to the user's record. This service ensures that each user has a `unique QR code` linked to their profile.

#### PayInstallment
This service handles the payment of loan installments. It checks the user's balance and processes the payment based on the loan's payment method. If sufficient funds are available, it initiates `repayment`, updates loan and installment records, and creates necessary documents and transaction records. If funds are insufficient, it creates an unpaid installment document and `schedules` the next installment if needed.

#### Verify
The Twillio::Verify class handles `Twilio verification` by sending a code to a specified receiver, ensuring the number is formatted correctly. The call method checks the verification status and returns true if approved. It includes robust `error handling`: if an exception occurs, it logs the error message and returns false. This approach ensures `secure verification` while providing clear feedback on any issues encountered.

### Stylesheets

---
These `SCSS` files showcase my versatile `styling approach` across different projects. They illustrate clean, modular design, responsive layouts, and interactive elements like dynamic navigation menus and innovative file inputs. Each sample reflects our commitment to modern, maintainable code and `user-centric design`.

### Views

---

The views handle `dynamic listings` with role-based filters and efficient code reuse through `partials` and `helpers`. They use form helpers like form_tag, select_tag, and options_from_collection_for_select for form creation and dropdowns. The views adapt URLs for filtering based on user roles and incorporate `Stimulus` for managing `interactive elements`. They also include functionalities such as displaying item lists in tables with CRUD operations, conditionally rendering content based on user roles, and providing modals for adding and editing items. Pagination is implemented to manage large datasets effectively.

## Summary

---
This repository showcases `well-structured` code samples for a Rails application, following `best practices` and `design patterns`. The controllers manage course and madrassa data securely, with robust authentication and error handling. The helpers module enhances student data management, offering utility functions and integrating with Stimulus for responsive form elements. In javascript, Stimulus controllers provide dynamic image previews and form updates, ensuring a seamless user experience. The models utilize clean code practices, with Ability managing user permissions, Course handling course-related data, and Student ensuring robust data integrity and notifications. The services include AddressService for API interactions and Twillio::Verify for secure verification with error handling. The views implement role-based filters using partials and helpers, with Stimulus managing interactive elements. This setup emphasizes modularity, maintainability, and `user-friendly` design.
