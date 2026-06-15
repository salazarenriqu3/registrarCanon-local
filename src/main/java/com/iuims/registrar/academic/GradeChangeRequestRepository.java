package com.iuims.registrar.academic;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GradeChangeRequestRepository extends JpaRepository<GradeChangeRequest, Integer> {
    List<GradeChangeRequest> findByStatus(String status);
    List<GradeChangeRequest> findByGradeId(Long gradeId);
}
