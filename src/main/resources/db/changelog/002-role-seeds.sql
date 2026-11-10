--liquibase formatted sql

--changeset Phani5611:023-seed-role-codes
INSERT INTO roles (id, code, label, description) VALUES
  ('00000000-0000-4000-8000-000000000001', 'SUPER_ADMIN', 'Super admin', 'System administration'),
  ('00000000-0000-4000-8000-000000000002', 'OPS_LEAD', 'Operations lead', 'Operations leadership'),
  ('00000000-0000-4000-8000-000000000003', 'OPS_ADMIN', 'Operations admin', 'Operational work'),
  ('00000000-0000-4000-8000-000000000004', 'CLIENT_USER', 'Client user', 'Client workspace access');
--rollback DELETE FROM roles WHERE code IN ('SUPER_ADMIN', 'OPS_LEAD', 'OPS_ADMIN', 'CLIENT_USER');
