package com.iuims.registrar.core;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

class EnrollmentPeriodPolicyTest {

    @Test
    void emptyDatesDoNotBlock() {
        LocalDate today = LocalDate.of(2026, 6, 19);
        assertFalse(EnrollmentPeriodPolicy.isBeforeEnrollmentOpen(today, ""));
        assertFalse(EnrollmentPeriodPolicy.isEnrollmentClosed(today, null));
        assertFalse(EnrollmentPeriodPolicy.isAddDropClosed(today, "   "));
    }

    @Test
    void enrollmentOpenDateBlocksBeforeOpen() {
        LocalDate today = LocalDate.of(2026, 6, 10);
        assertTrue(EnrollmentPeriodPolicy.isBeforeEnrollmentOpen(today, "2026-06-15"));
        assertFalse(EnrollmentPeriodPolicy.isBeforeEnrollmentOpen(today, "2026-06-01"));
    }

    @Test
    void enrollmentCloseDateBlocksAfterClose() {
        LocalDate today = LocalDate.of(2026, 6, 20);
        assertTrue(EnrollmentPeriodPolicy.isEnrollmentClosed(today, "2026-06-19"));
        assertFalse(EnrollmentPeriodPolicy.isEnrollmentClosed(today, "2026-06-20"));
    }

    @Test
    void addDropCloseDateBlocksAfterClose() {
        LocalDate today = LocalDate.of(2026, 7, 2);
        assertTrue(EnrollmentPeriodPolicy.isAddDropClosed(today, "2026-07-01"));
        assertFalse(EnrollmentPeriodPolicy.isAddDropClosed(today, "2026-07-02"));
    }
}
