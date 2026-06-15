package com.iuims.registrar.academic;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AcademicTermPolicyRepository extends JpaRepository<AcademicTermPolicy, Integer> {
}
