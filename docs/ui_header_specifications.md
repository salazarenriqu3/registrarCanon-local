# Registrar Portal - UI Header Specifications

This document outlines the design specifications, logic, and exact code required to reproduce and fix the UI issues present in the global header (`layout.html`).

## 1. Global Search Bar Redesign
### Design Specifications
- **Visual Consistency:** The search bar must match the `.search-bar` or `.form-control` styles used throughout the application to ensure a uniform base template look.
- **CSS Variables:** The current implementation uses undefined variables. It must use established theme tokens from `theme-eac.css`:
  - Border: `var(--border)` or `var(--border-strong)`
  - Background: `var(--white)` or `var(--off-white)`
  - Text: `var(--text-primary)`
  - Placeholder: `var(--text-muted)`
- **Alignment:** The parent container (`.topbar-right`) uses Flexbox (`display: flex; align-items: center`). The search form must drop `display: inline-block` and also utilize flex properties to maintain perfectly centered vertical alignment with adjacent icon buttons.

### Implementation HTML
Replace the existing `#globalSearchForm` in `layout.html` with:
```html
<form id="globalSearchForm" onsubmit="handleGlobalSearch(event)" style="display:flex; align-items:center; gap:8px; margin-right: 1rem; background: var(--white); border: 0.5px solid var(--border-strong); padding: 4px 12px; border-radius: 6px;">
    <input type="text" id="globalSearchInput" placeholder="Search features..." style="border: none; background: transparent; outline: none; font-size: 13px; color: var(--text-primary); width: 180px;" />
    <button type="submit" aria-label="Search" style="background: none; border: none; cursor: pointer; color: var(--text-muted); display: flex; align-items: center; justify-content: center; padding: 0;">
        <i class="ti ti-search" aria-hidden="true" style="font-size: 15px;"></i>
    </button>
</form>
```

## 2. Notification Badge Fix
### Design Specifications
- **Colors:** The current implementation uses an undefined variable `var(--danger-color)`. It must be updated to use `var(--red)` for the background and `var(--white)` for the text to map correctly to the EAC theme.
- **Display Logic:** The UI currently renders *both* a dot (`.notif-dot`) and a numbered badge (`.notif-badge`) simultaneously. The logic should be simplified to show only the numbered badge when the count is > 0, preventing overlap.
- **Positioning:** Absolute positioning on the top-right corner of the relative parent `.top-icon-btn`.

### Implementation HTML
Replace the existing notification anchor tag in `layout.html` with:
```html
<a th:href="@{/admin/admission-acceptance}" class="top-icon-btn" title="Notifications" aria-label="Notifications" style="text-decoration:none; position:relative;">
    <i class="ti ti-bell" aria-hidden="true"></i>
    <!-- Consolidate to only the numbered badge using correct theme variables -->
    <span class="notif-badge" th:if="${pendingApps != null && pendingApps > 0}" th:text="${pendingApps}" style="position:absolute; top:-4px; right:-4px; background:var(--red); color:var(--white); font-size:0.6rem; padding:0.1rem 0.3rem; border-radius:10px; font-weight:bold; line-height:1;">1</span>
</a>
```

## 3. Global Search Behavior (JavaScript)
### Functional Specifications
- **Objective:** Act as a command palette to navigate the user to specific administrative modules based on keyword detection in the search string.
- **Improvements:** Added trimming, lowercasing, broader keyword mapping, and a user-friendly alert fallback if the query is unrecognized, rather than silently defaulting to the settings page.

### Implementation Script
Replace the existing `handleGlobalSearch` function in `layout.html` with:
```javascript
function handleGlobalSearch(e) {
    e.preventDefault();
    const queryInput = document.getElementById('globalSearchInput');
    const query = queryInput.value.toLowerCase().trim();
    
    if (!query) return;
    
    // Keyword matching logic
    if (query.includes('student') || query.includes('directory')) {
        window.location.href = '/admin/student-manager';
    } else if (query.includes('admission') || query.includes('applicant')) {
        window.location.href = '/admin/admission-acceptance';
    } else if (query.includes('fee') || query.includes('finance') || query.includes('payment')) {
        window.location.href = '/admin/term-fees';
    } else if (query.includes('grade') || query.includes('record')) {
        window.location.href = '/admin/approvals';
    } else if (query.includes('curriculum') || query.includes('subject') || query.includes('class')) {
        window.location.href = '/admin/curriculum';
    } else if (query.includes('setting')) {
        window.location.href = '/admin/settings';
    } else if (query.includes('scholarship')) {
        window.location.href = '/admin/scholarships';
    } else {
        // Fallback action
        alert("No exact module found for '" + query + "'. Try terms like 'student', 'admission', or 'grades'.");
        queryInput.value = ''; // clear input
    }
}
```
