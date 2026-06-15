package com.iuims.registrar.academic;

public record ClassInfoDto(
    int scheduleId,
    int sectionId,
    String sectionCode,
    int termId,
    String status,
    String courseCode,
    String description,
    String facultyFirst,
    String facultyLast,
    String prettySchedule
) {}
