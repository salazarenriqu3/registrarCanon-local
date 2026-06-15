package com.iuims.registrar.curriculum;

import jakarta.persistence.*;

@Entity
@Table(name = "courses")
public class Course {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "course_id")
    private Integer courseId;

    @Column(name = "course_code", length = 20)
    private String courseCode;

    @Column(name = "course_title", length = 150)
    private String courseTitle;

    @Column(name = "department_id")
    private Integer departmentId;

    @Column(name = "credit_units")
    private Integer creditUnits;

    // Getters and Setters
    public Integer getCourseId() { return courseId; }
    public void setCourseId(Integer courseId) { this.courseId = courseId; }

    public String getCourseCode() { return courseCode; }
    public void setCourseCode(String courseCode) { this.courseCode = courseCode; }

    public String getCourseTitle() { return courseTitle; }
    public void setCourseTitle(String courseTitle) { this.courseTitle = courseTitle; }

    public Integer getDepartmentId() { return departmentId; }
    public void setDepartmentId(Integer departmentId) { this.departmentId = departmentId; }

    public Integer getCreditUnits() { return creditUnits; }
    public void setCreditUnits(Integer creditUnits) { this.creditUnits = creditUnits; }
}
