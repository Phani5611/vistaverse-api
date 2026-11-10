--liquibase formatted sql

--changeset Phani5611:022-foundation-indexes splitStatements:true
CREATE INDEX ix_users_role_enabled ON users (role, account_enabled);
CREATE INDEX ix_login_activity_user_time ON login_activity (user_id, created_at DESC, id);
CREATE INDEX ix_login_activity_fingerprint_time ON login_activity (identifier_fingerprint, created_at DESC) WHERE identifier_fingerprint IS NOT NULL;
-- CREATE INDEX ix_login_activity_recent ON login_activity (created_at DESC, id);
CREATE UNIQUE INDEX ux_login_activity_session_event ON login_activity (session_reference, event_type)
    WHERE session_reference IS NOT NULL AND event_type IN ('LOGIN_SUCCESS', 'LOGOUT');
-- CREATE INDEX ix_leads_created ON leads (created_at DESC, id);
CREATE INDEX ix_leads_status_created ON leads (status, created_at DESC, id);
CREATE INDEX ix_consent_log_lead_created ON consent_log (lead_id, created_at DESC, id);
CREATE INDEX ix_quote_requests_lead_created ON quote_requests (lead_id, created_at DESC, id);
CREATE INDEX ix_quote_requests_status_created ON quote_requests (status, created_at DESC);
CREATE INDEX ix_quote_requests_assigned_status_due ON quote_requests (assigned_to, status, next_follow_up_at);
CREATE INDEX ix_quote_requests_due ON quote_requests (next_follow_up_at)
    WHERE next_follow_up_at IS NOT NULL AND status IN ('FOLLOW_UP', 'PENDING');
CREATE INDEX ix_otp_lead_created ON otp_challenges (lead_id, created_at DESC);
CREATE INDEX ix_otp_user_created ON otp_challenges (user_id, created_at DESC) WHERE user_id IS NOT NULL;
CREATE INDEX ix_otp_resend_parent ON otp_challenges (resend_of_id) WHERE resend_of_id IS NOT NULL;
CREATE UNIQUE INDEX ux_otp_one_live_quote_per_lead ON otp_challenges (lead_id)
    WHERE purpose = 'QUOTE_REQUEST' AND status IN ('CREATED', 'SENT');
CREATE UNIQUE INDEX ux_otp_one_live_reset_per_user ON otp_challenges (user_id)
    WHERE purpose = 'PASSWORD_RESET' AND status IN ('CREATED', 'SENT');
CREATE INDEX ix_quote_events_request_time ON quote_request_events (quote_request_id, created_at DESC, id);
--rollback DROP INDEX ix_quote_events_request_time;
--rollback DROP INDEX ux_otp_one_live_reset_per_user;
--rollback DROP INDEX ux_otp_one_live_quote_per_lead;
--rollback DROP INDEX ix_otp_resend_parent;
--rollback DROP INDEX ix_otp_user_created;
--rollback DROP INDEX ix_otp_lead_created;
--rollback DROP INDEX ix_quote_requests_due;
--rollback DROP INDEX ix_quote_requests_assigned_status_due;
--rollback DROP INDEX ix_quote_requests_status_created;
--rollback DROP INDEX ix_quote_requests_lead_created;
--rollback DROP INDEX ix_consent_log_lead_created;
--rollback DROP INDEX ix_leads_status_created;
--rollback DROP INDEX ix_leads_created;
--rollback DROP INDEX ux_login_activity_session_event;
--rollback DROP INDEX ix_login_activity_recent;
--rollback DROP INDEX ix_login_activity_fingerprint_time;
--rollback DROP INDEX ix_login_activity_user_time;
--rollback DROP INDEX ix_users_role_enabled;
