package com.iuims.registrar.curriculum;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CurriculumCourseRepository extends JpaRepository<CurriculumCourse, Integer> {
    List<CurriculumCourse> findByCurriculumId(Integer curriculumId);
    List<CurriculumCourse> findByCourseId(Integer courseId);
}
