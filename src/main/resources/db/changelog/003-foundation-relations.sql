--liquibase formatted sql

--changeset Phani5611:009-add-audit-foreign-keys splitStatements:true
ALTER TABLE roles ADD CONSTRAINT fk_roles_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE roles ADD CONSTRAINT fk_roles_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE users ADD CONSTRAINT fk_users_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE users ADD CONSTRAINT fk_users_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE user_roles ADD CONSTRAINT fk_user_roles_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE user_roles ADD CONSTRAINT fk_user_roles_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE login_activity ADD CONSTRAINT fk_login_activity_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE login_activity ADD CONSTRAINT fk_login_activity_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE leads ADD CONSTRAINT fk_leads_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE leads ADD CONSTRAINT fk_leads_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE consent_log ADD CONSTRAINT fk_consent_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE consent_log ADD CONSTRAINT fk_consent_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE otp_challenges ADD CONSTRAINT fk_otp_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE otp_challenges ADD CONSTRAINT fk_otp_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE quote_requests ADD CONSTRAINT fk_quote_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE quote_requests ADD CONSTRAINT fk_quote_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE quote_request_events ADD CONSTRAINT fk_quote_events_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE quote_request_events ADD CONSTRAINT fk_quote_events_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE RESTRICT;
--rollback ALTER TABLE quote_request_events DROP CONSTRAINT fk_quote_events_updated_by;
--rollback ALTER TABLE quote_request_events DROP CONSTRAINT fk_quote_events_created_by;
--rollback ALTER TABLE quote_requests DROP CONSTRAINT fk_quote_updated_by;
--rollback ALTER TABLE quote_requests DROP CONSTRAINT fk_quote_created_by;
--rollback ALTER TABLE otp_challenges DROP CONSTRAINT fk_otp_updated_by;
--rollback ALTER TABLE otp_challenges DROP CONSTRAINT fk_otp_created_by;
--rollback ALTER TABLE consent_log DROP CONSTRAINT fk_consent_updated_by;
--rollback ALTER TABLE consent_log DROP CONSTRAINT fk_consent_created_by;
--rollback ALTER TABLE leads DROP CONSTRAINT fk_leads_updated_by;
--rollback ALTER TABLE leads DROP CONSTRAINT fk_leads_created_by;
--rollback ALTER TABLE login_activity DROP CONSTRAINT fk_login_activity_updated_by;
--rollback ALTER TABLE login_activity DROP CONSTRAINT fk_login_activity_created_by;
--rollback ALTER TABLE user_roles DROP CONSTRAINT fk_user_roles_updated_by;
--rollback ALTER TABLE user_roles DROP CONSTRAINT fk_user_roles_created_by;
--rollback ALTER TABLE users DROP CONSTRAINT fk_users_updated_by;
--rollback ALTER TABLE users DROP CONSTRAINT fk_users_created_by;
--rollback ALTER TABLE roles DROP CONSTRAINT fk_roles_updated_by;
--rollback ALTER TABLE roles DROP CONSTRAINT fk_roles_created_by;
