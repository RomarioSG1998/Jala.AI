-- ==========================================
-- EMPLOYEE MODULE PERMISSIONS
-- ==========================================
-- Tracks which modules each FIELD_OPERATOR employee can access per farm.
-- If no record exists for a module, default behavior is ALLOWED.
-- Only explicit revocations are stored (or full explicit initialization).

CREATE TABLE employee_module_permission (
    employee_id UUID NOT NULL,
    farm_id     UUID NOT NULL,
    module_name VARCHAR(100) NOT NULL,
    is_enabled  BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (employee_id, farm_id, module_name),
    CONSTRAINT fk_emp_perm_user FOREIGN KEY (employee_id) REFERENCES global_user (id) ON DELETE CASCADE,
    CONSTRAINT fk_emp_perm_farm FOREIGN KEY (farm_id)     REFERENCES farm_tenant  (id) ON DELETE CASCADE
);
