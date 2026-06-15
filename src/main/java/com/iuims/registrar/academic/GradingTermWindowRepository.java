package com.iuims.registrar.academic;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GradingTermWindowRepository extends JpaRepository<GradingTermWindow, Long> {
    List<GradingTermWindow> findByTermId(Integer termId);
    GradingTermWindow findByTermIdAndGradingPeriod(Integer termId, String gradingPeriod);
}
