--liquibase formatted sql

--changeset Phani5611:010-role-code-immutable-function splitStatements:false
CREATE FUNCTION forbid_role_code_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.code IS DISTINCT FROM OLD.code THEN
        RAISE EXCEPTION 'roles.code is immutable';
    END IF;
    RETURN NEW;
END;
$$;
--rollback DROP FUNCTION forbid_role_code_change();

--changeset Phani5611:011-role-code-immutable-trigger
CREATE TRIGGER trg_roles_code_immutable BEFORE UPDATE OF code ON roles
FOR EACH ROW EXECUTE FUNCTION forbid_role_code_change();
--rollback DROP TRIGGER trg_roles_code_immutable ON roles;

--changeset Phani5611:012-role-mapping-function splitStatements:false
CREATE FUNCTION check_user_role_mapping() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    subject_id uuid;
BEGIN
    IF TG_TABLE_NAME = 'users' THEN
        subject_id := NEW.id;
    ELSIF TG_OP = 'DELETE' THEN
        subject_id := OLD.user_id;
    ELSE
        subject_id := NEW.user_id;
    END IF;

    PERFORM 1 FROM users WHERE id = subject_id FOR UPDATE;

    IF EXISTS (
        SELECT 1 FROM users u
        WHERE u.id = subject_id
          AND NOT EXISTS (
              SELECT 1 FROM user_roles ur
              JOIN roles r ON r.id = ur.role_id
              WHERE ur.user_id = u.id AND ur.is_active AND r.code = u.role
          )
    ) THEN
        RAISE EXCEPTION 'users.role must have an active user_roles mapping for user %', subject_id;
    END IF;

    IF TG_TABLE_NAME = 'user_roles' AND TG_OP = 'UPDATE' AND OLD.user_id IS DISTINCT FROM NEW.user_id THEN
        PERFORM 1 FROM users WHERE id = OLD.user_id FOR UPDATE;
        IF EXISTS (
            SELECT 1 FROM users u
            WHERE u.id = OLD.user_id
              AND NOT EXISTS (
                  SELECT 1 FROM user_roles ur
                  JOIN roles r ON r.id = ur.role_id
                  WHERE ur.user_id = u.id AND ur.is_active AND r.code = u.role
              )
        ) THEN
            RAISE EXCEPTION 'users.role must have an active user_roles mapping for user %', OLD.user_id;
        END IF;
    END IF;
    RETURN NULL;
END;
$$;
--rollback DROP FUNCTION check_user_role_mapping();

--changeset Phani5611:013-role-mapping-triggers splitStatements:true
CREATE CONSTRAINT TRIGGER ctr_users_role_mapping
AFTER INSERT OR UPDATE ON users DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_user_role_mapping();
CREATE CONSTRAINT TRIGGER ctr_user_roles_mapping
AFTER INSERT OR UPDATE OR DELETE ON user_roles DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_user_role_mapping();
--rollback DROP TRIGGER ctr_user_roles_mapping ON user_roles;
--rollback DROP TRIGGER ctr_users_role_mapping ON users;

--changeset Phani5611:014-clear-contact-verification-function splitStatements:false
CREATE FUNCTION clear_changed_contact_verification() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.phone IS DISTINCT FROM OLD.phone THEN
        NEW.phone_verified_at := NULL;
    END IF;
    IF NEW.email_address IS DISTINCT FROM OLD.email_address THEN
        NEW.email_verified_at := NULL;
    END IF;
    RETURN NEW;
END;
$$;
--rollback DROP FUNCTION clear_changed_contact_verification();

--changeset Phani5611:015-clear-contact-verification-trigger
CREATE TRIGGER trg_users_clear_changed_verification
BEFORE UPDATE OF phone, email_address ON users
FOR EACH ROW EXECUTE FUNCTION clear_changed_contact_verification();
--rollback DROP TRIGGER trg_users_clear_changed_verification ON users;

--changeset Phani5611:016-login-activity-immutable-function splitStatements:false
CREATE FUNCTION forbid_login_activity_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'login_activity is insert-only';
END;
$$;
--rollback DROP FUNCTION forbid_login_activity_mutation();

--changeset Phani5611:017-login-activity-immutable-trigger
CREATE TRIGGER trg_login_activity_immutable
BEFORE UPDATE OR DELETE ON login_activity
FOR EACH ROW EXECUTE FUNCTION forbid_login_activity_mutation();
--rollback DROP TRIGGER trg_login_activity_immutable ON login_activity;

--changeset Phani5611:018-quote-events-immutable-function splitStatements:false
CREATE FUNCTION forbid_quote_event_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'quote_request_events is insert-only';
END;
$$;
--rollback DROP FUNCTION forbid_quote_event_mutation();

--changeset Phani5611:019-quote-events-immutable-trigger
CREATE TRIGGER trg_quote_events_immutable
BEFORE UPDATE OR DELETE ON quote_request_events
FOR EACH ROW EXECUTE FUNCTION forbid_quote_event_mutation();
--rollback DROP TRIGGER trg_quote_events_immutable ON quote_request_events;

--changeset Phani5611:020-quote-verification-function splitStatements:false
CREATE FUNCTION check_quote_request_verification() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    PERFORM 1 FROM leads WHERE id = NEW.lead_id FOR UPDATE;

    IF NEW.creation_method = 'PUBLIC_REPEAT' AND NOT EXISTS (
        SELECT 1 FROM otp_challenges c
        WHERE c.id = NEW.repeat_verification_id
          AND c.lead_id = NEW.lead_id
          AND c.purpose = 'QUOTE_REQUEST'
          AND c.status = 'VERIFIED'
          AND c.consumed_at IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'public repeat quote request requires consumed QUOTE_REQUEST verification';
    END IF;
    IF NEW.creation_method = 'PUBLIC_FIRST' AND EXISTS (
        SELECT 1 FROM quote_requests q
        WHERE q.lead_id = NEW.lead_id AND q.id <> NEW.id
    ) THEN
        RAISE EXCEPTION 'PUBLIC_FIRST is only valid for the first request of a lead';
    END IF;
    RETURN NULL;
END;
$$;
--rollback DROP FUNCTION check_quote_request_verification();

--changeset Phani5611:021-quote-verification-trigger
CREATE CONSTRAINT TRIGGER ctr_quote_request_verification
AFTER INSERT OR UPDATE ON quote_requests
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_quote_request_verification();
--rollback DROP TRIGGER ctr_quote_request_verification ON quote_requests;

--changeset Phani5611:024-consent-log-immutable-function splitStatements:false
CREATE FUNCTION forbid_consent_log_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'consent_log is insert-only';
END;
$$;
--rollback DROP FUNCTION forbid_consent_log_mutation();

--changeset Phani5611:025-consent-log-immutable-trigger
CREATE TRIGGER trg_consent_log_immutable
BEFORE UPDATE OR DELETE ON consent_log
FOR EACH ROW EXECUTE FUNCTION forbid_consent_log_mutation();
--rollback DROP TRIGGER trg_consent_log_immutable ON consent_log;
