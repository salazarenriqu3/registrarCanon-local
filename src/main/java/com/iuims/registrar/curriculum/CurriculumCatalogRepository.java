package com.iuims.registrar.curriculum;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CurriculumCatalogRepository extends JpaRepository<CurriculumCatalog, String> {
}
