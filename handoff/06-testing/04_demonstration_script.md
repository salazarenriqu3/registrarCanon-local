# Scholarship Module — Phase 2 Demonstration Script

This script is designed for your live audience/panel to showcase the robustness and automation of the newly integrated Scholarship features.

---

## Part 1: The Mega Integration (Setting the Stage)
*Goal: Show the panel that the system handles massive scale right out of the box.*

1. **Open the Database or Application Dashboard**
2. **Speaker Notes:** "To test the resilience of our new architecture, we've executed a massive procedural data generator. It didn't just create dummy data—it simulated over 1,000 real applicants, automatically sorted them into enrolled students, mapped them to our real BSIT curriculum, generated active enrollments, and simulated thousands of random Pass/Fail grades natively inside the legacy Registrar Engine."
3. **Action:** Log into the Admin panel (`admin` / `1234`) and navigate to the **Students List**. Show the huge list of `2026-Txxxx` generated students.

## Part 2: The External Scholarship Blocker
*Goal: Demonstrate precise business logic and data integrity rules.*

1. **Speaker Notes:** "We introduced 4 classifications of scholarships. Let's look at External Scholarships (like Barangay or LGU grants). A critical business rule is that external grants *cannot* be officially attached to someone who is merely an applicant; they must have an officially generated Student ID."
2. **Action:** 
   * Navigate to the **Admissions** side or attempt to run the helper macro: `CALL grant_manual_scholarship(<applicant_id>, 'Barangay Scholarship', 1);`
   * **Highlight the system response:** Immediately show the panel the Error 45000: *'Manual scholarship requires an officially generated Student ID.'*
   * Now, select an explicitly enrolled test student (e.g., `2026-T0005`), assign the Barangay Scholarship, and show it successfully attaching to their profile.

## Part 3: The Internal Grade-Based Auto-Evaluator (The Star Feature)
*Goal: Showcase pure automation. Academic scholars shouldn't require manual Registrar tracking.*

1. **Speaker Notes:** "For internal scholarships like Dean's Lister or Academic, tracking whether a student maintains their eligibility across thousands of records is tedious. We've automated it using the grading workflow."
2. **Action:**
   * Pick one of the Test Students who randomly received an Internal Scholarship during the database generation.
   * Go into the grading interface (or run the macro) to simulate giving them a **`FAILED`** grade in one of their subjects.
   * **Execute the Evaluator:** Emphasize to the panel that at the end of the term, the system runs its evaluation automatically (you can trigger this live by running `CALL evaluate_internal_scholarships();` in MySQL).
   * **Refresh the Student's Profile:** Show that the student's Active Scholarship was instantly converted dynamically to **REVOKED** due to failing a subject. 

## Part 4: The Student Portal Experience
*Goal: Show the front-end user experience.*

1. **Action:** Log out of Admin. 
2. **Action:** Log in as one of the generated test students who received a scholarship (any `2026-Txxxx` student with `password123`).
3. **Navigate to the Finance/Scholarship Tab:**
4. **Speaker Notes:** "The student gets immediate transparent feedback. Instead of queuing at the Registrar, their portal dynamically queries their evaluation history, displaying their beautiful 'Active Dean's Lister' badge, or, if they fell behind academically, the revoked status warning."

---

*Once the demonstration concludes, you can cleanly wipe all 1000+ test records by executing `CALL reset_all_test_data();` in your database without harming your real historical records!*
