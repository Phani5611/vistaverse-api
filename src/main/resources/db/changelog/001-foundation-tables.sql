--liquibase formatted sql

--changeset Phani5611:001-foundation-tables splitStatements:true


CREATE TABLE roles (
    id uuid PRIMARY KEY,
    code varchar(40) NOT NULL UNIQUE,
    label varchar(100) NOT NULL,
    description varchar(500),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT ck_roles_code CHECK (code ~ '^[A-Z][A-Z_]*$'),
    CONSTRAINT ck_roles_label CHECK (nullif(btrim(label), '') IS NOT NULL)
);


CREATE TABLE users (
    id uuid PRIMARY KEY,
    name varchar(100) NOT NULL,
    phone varchar(16) UNIQUE,
    email_address varchar(254) UNIQUE,
    phone_verified_at timestamptz,
    email_verified_at timestamptz,
    password_hash varchar(512),
    password_changed_at timestamptz,
    city varchar(100),
    state varchar(100),
    role varchar(40) NOT NULL,
    last_login_at timestamptz,
    account_enabled boolean NOT NULL DEFAULT false,
    locked boolean NOT NULL DEFAULT false,
    failed_login_attempts integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT fk_users_role FOREIGN KEY (role) REFERENCES roles(code) ON DELETE RESTRICT,
    CONSTRAINT ck_users_name CHECK (char_length(btrim(name)) BETWEEN 2 AND 100 AND name = btrim(name)),
    CONSTRAINT ck_users_phone CHECK (phone IS NULL OR phone ~ '^\+91[6-9][0-9]{9}$'),
    CONSTRAINT ck_users_email CHECK (email_address IS NULL OR (email_address = lower(btrim(email_address)) AND email_address <> '')),
    CONSTRAINT ck_users_verified_phone CHECK (phone_verified_at IS NULL OR phone IS NOT NULL),
    CONSTRAINT ck_users_verified_email CHECK (email_verified_at IS NULL OR email_address IS NOT NULL),
    CONSTRAINT ck_users_failed_login CHECK (failed_login_attempts >= 0),
    CONSTRAINT ck_users_enabled_credentials CHECK (NOT account_enabled OR
        (nullif(btrim(password_hash), '') IS NOT NULL AND password_changed_at IS NOT NULL
         AND (phone IS NOT NULL OR email_address IS NOT NULL)))
);


CREATE TABLE user_roles (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    role_id uuid NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT uq_user_roles_user_role UNIQUE (user_id, role_id)
);


CREATE TABLE login_activity (
    id uuid PRIMARY KEY,
    user_id uuid REFERENCES users(id) ON DELETE RESTRICT,
    event_type varchar(32) NOT NULL,
    identifier_fingerprint bytea,
    session_reference uuid,
    ip_address inet,
    user_agent varchar(2048),
    reason_code varchar(64),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT ck_login_activity_event CHECK (event_type IN ('LOGIN_SUCCESS','LOGIN_FAILURE','LOGOUT')),
    CONSTRAINT ck_login_activity_session CHECK (event_type = 'LOGIN_FAILURE' OR
        (user_id IS NOT NULL AND session_reference IS NOT NULL)),
    CONSTRAINT ck_login_activity_failure CHECK (event_type <> 'LOGIN_FAILURE' OR
        (nullif(btrim(reason_code), '') IS NOT NULL AND
         (user_id IS NOT NULL OR identifier_fingerprint IS NOT NULL))),
    CONSTRAINT ck_login_activity_immutable_audit CHECK
        (updated_at = created_at AND created_by IS NULL AND updated_by IS NULL)
);


CREATE TABLE leads (
    id uuid PRIMARY KEY,
    name varchar(100) NOT NULL,
    phone varchar(16) NOT NULL UNIQUE,
    email_address varchar(254) UNIQUE,
    city varchar(100) NOT NULL,
    state varchar(100),
    user_id uuid UNIQUE REFERENCES users(id) ON DELETE RESTRICT,
    status varchar(16) NOT NULL DEFAULT 'ACTIVE',
    privacy_consent_given boolean NOT NULL DEFAULT false,
    privacy_consented_at timestamptz,
    privacy_withdrawn_at timestamptz,
    privacy_notice_version varchar(20),
    terms_accepted_at timestamptz,
    terms_version varchar(20),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT ck_leads_name CHECK (char_length(btrim(name)) BETWEEN 2 AND 100 AND name = btrim(name)),
    CONSTRAINT ck_leads_phone CHECK (phone ~ '^[+][1-9][0-9]{1,14}$'),
    CONSTRAINT ck_leads_email CHECK (email_address IS NULL OR (email_address = lower(btrim(email_address)) AND email_address <> '')),
    CONSTRAINT ck_leads_city CHECK (char_length(btrim(city)) BETWEEN 2 AND 100 AND city = btrim(city)),
    CONSTRAINT ck_leads_state CHECK (state IS NULL OR nullif(btrim(state), '') IS NOT NULL),
    CONSTRAINT ck_leads_status CHECK (status IN ('ACTIVE','INACTIVE')),
    CONSTRAINT ck_leads_privacy_grant CHECK (NOT privacy_consent_given OR
        (privacy_consented_at IS NOT NULL AND
         nullif(btrim(privacy_notice_version), '') IS NOT NULL AND
         privacy_withdrawn_at IS NULL)),
    CONSTRAINT ck_leads_privacy_withdrawal CHECK (privacy_withdrawn_at IS NULL OR
        (NOT privacy_consent_given AND privacy_consented_at IS NOT NULL)),
    CONSTRAINT ck_leads_privacy_state CHECK
        (privacy_consent_given OR privacy_consented_at IS NULL OR privacy_withdrawn_at IS NOT NULL),
    CONSTRAINT ck_leads_privacy_version CHECK
        (privacy_consented_at IS NOT NULL OR privacy_notice_version IS NULL),
    CONSTRAINT ck_leads_terms CHECK
        ((terms_accepted_at IS NULL AND terms_version IS NULL) OR
         (terms_accepted_at IS NOT NULL AND nullif(btrim(terms_version), '') IS NOT NULL))
);

CREATE TABLE consent_log (
    id uuid PRIMARY KEY,
    lead_id uuid NOT NULL REFERENCES leads(id) ON DELETE RESTRICT,
    record_type varchar(32) NOT NULL,
    event_type varchar(16) NOT NULL,
    document_version varchar(20),
    source varchar(20) NOT NULL,
    evidence_reference varchar(500),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT ck_consent_record_type CHECK (record_type IN
        ('PRIVACY_PROCESSING','TERMS','MARKETING_EMAIL','MARKETING_WHATSAPP')),
    CONSTRAINT ck_consent_event_type CHECK
        ((record_type = 'TERMS' AND event_type = 'ACCEPTED') OR
         (record_type <> 'TERMS' AND event_type IN ('GRANTED','WITHDRAWN'))),
    CONSTRAINT ck_consent_document_version CHECK
        (event_type = 'WITHDRAWN' OR nullif(btrim(document_version), '') IS NOT NULL),
    CONSTRAINT ck_consent_source_actor CHECK
        ((source = 'PUBLIC_FORM' AND created_by IS NULL AND evidence_reference IS NULL) OR
         (source = 'CUSTOMER_PORTAL' AND created_by IS NOT NULL AND evidence_reference IS NULL) OR
         (source = 'ADMIN_RECORDED' AND created_by IS NOT NULL AND
          nullif(btrim(evidence_reference), '') IS NOT NULL)),
    CONSTRAINT ck_consent_immutable_audit CHECK
        (updated_at = created_at AND updated_by IS NULL)
);


CREATE TABLE otp_challenges (
    id uuid PRIMARY KEY,
    lead_id uuid REFERENCES leads(id) ON DELETE RESTRICT,
    user_id uuid REFERENCES users(id) ON DELETE RESTRICT,
    purpose varchar(32) NOT NULL,
    destination_channel varchar(16) NOT NULL,
    destination_address varchar(254) NOT NULL,
    request_fingerprint bytea,
    resend_of_id uuid,
    initiated_by varchar(8) NOT NULL,
    verifier_hash bytea NOT NULL,
    status varchar(32) NOT NULL DEFAULT 'CREATED',
    expires_at timestamptz NOT NULL,
    consumed_at timestamptz,
    invalidated_at timestamptz,
    sent_at timestamptz,
    provider_error varchar(1000),
    admin_reason varchar(1000),
    failed_attempts integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT uq_otp_id_lead UNIQUE (id, lead_id),
    CONSTRAINT uq_otp_id_lead_purpose UNIQUE (id, lead_id, purpose),
    CONSTRAINT uq_otp_id_user_purpose UNIQUE (id, user_id, purpose),
    CONSTRAINT fk_otp_resend_lead FOREIGN KEY (resend_of_id, lead_id, purpose)
        REFERENCES otp_challenges(id, lead_id, purpose) ON DELETE RESTRICT,
    CONSTRAINT fk_otp_resend_user FOREIGN KEY (resend_of_id, user_id, purpose)
        REFERENCES otp_challenges(id, user_id, purpose) ON DELETE RESTRICT,
    CONSTRAINT ck_otp_purpose CHECK (purpose IN ('QUOTE_REQUEST','PASSWORD_RESET')),
    CONSTRAINT ck_otp_subject CHECK (
        (purpose = 'QUOTE_REQUEST' AND lead_id IS NOT NULL AND user_id IS NULL AND request_fingerprint IS NOT NULL)
        OR (purpose = 'PASSWORD_RESET' AND user_id IS NOT NULL AND lead_id IS NULL AND request_fingerprint IS NULL)),
    CONSTRAINT ck_otp_channel CHECK (destination_channel IN ('SMS','WHATSAPP','EMAIL')),
    CONSTRAINT ck_otp_destination CHECK (nullif(btrim(destination_address), '') IS NOT NULL),
    CONSTRAINT ck_otp_initiator CHECK (initiated_by IN ('PUBLIC','ADMIN')),
    CONSTRAINT ck_otp_actor CHECK ((initiated_by = 'PUBLIC' AND created_by IS NULL)
        OR (initiated_by = 'ADMIN' AND created_by IS NOT NULL)),
    CONSTRAINT ck_otp_reset_initiator CHECK (purpose <> 'PASSWORD_RESET' OR initiated_by = 'PUBLIC'),
    CONSTRAINT ck_otp_public_quote_channel CHECK
        (purpose <> 'QUOTE_REQUEST' OR initiated_by <> 'PUBLIC' OR destination_channel <> 'EMAIL'),
    CONSTRAINT ck_otp_admin_quote_email CHECK
        (purpose <> 'QUOTE_REQUEST' OR destination_channel <> 'EMAIL' OR
         (initiated_by = 'ADMIN' AND nullif(btrim(admin_reason), '') IS NOT NULL)),
    CONSTRAINT ck_otp_status CHECK (status IN
        ('CREATED','SENT','VERIFIED','SUPERSEDED','EXPIRED','DELIVERY_FAILED','LOCKED')),
    CONSTRAINT ck_otp_expiry CHECK (expires_at > created_at),
    CONSTRAINT ck_otp_failed_attempts CHECK (failed_attempts >= 0),
    CONSTRAINT ck_otp_verified_time CHECK (status <> 'VERIFIED' OR consumed_at IS NOT NULL),
    CONSTRAINT ck_otp_superseded_time CHECK (status <> 'SUPERSEDED' OR invalidated_at IS NOT NULL),
    CONSTRAINT ck_otp_sent_time CHECK (status <> 'SENT' OR sent_at IS NOT NULL)
);


CREATE TABLE quote_requests (
    id uuid PRIMARY KEY,
    lead_id uuid NOT NULL REFERENCES leads(id) ON DELETE RESTRICT,
    project_city varchar(100) NOT NULL,
    project_state varchar(100),
    home_type varchar(8) NOT NULL,
    budget_rupees bigint,
    customer_message varchar(1000),
    status varchar(32) NOT NULL DEFAULT 'FOLLOW_UP',
    creation_method varchar(16) NOT NULL,
    follow_up_count integer NOT NULL DEFAULT 0,
    assigned_to uuid REFERENCES users(id) ON DELETE RESTRICT,
    source varchar(64),
    repeat_verification_id uuid UNIQUE,
    next_follow_up_at timestamptz,
    lost_reason varchar(500),
    converted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT fk_quote_repeat_lead FOREIGN KEY (repeat_verification_id, lead_id)
        REFERENCES otp_challenges(id, lead_id) ON DELETE RESTRICT,
    CONSTRAINT ck_quote_city CHECK (char_length(btrim(project_city)) BETWEEN 2 AND 100 AND project_city = btrim(project_city)),
    CONSTRAINT ck_quote_state CHECK (project_state IS NULL OR nullif(btrim(project_state), '') IS NOT NULL),
    CONSTRAINT ck_quote_home_type CHECK (home_type IN ('1BHK','2BHK','3BHK','Villa')),
    CONSTRAINT ck_quote_budget CHECK (budget_rupees IS NULL OR budget_rupees BETWEEN 1 AND 999999999999),
    CONSTRAINT ck_quote_status CHECK (status IN ('FOLLOW_UP','PENDING','REQUESTED_NEW_REVISION','FAILED','SUCCESS')),
    CONSTRAINT ck_quote_creation_method CHECK (creation_method IN ('PUBLIC_FIRST','PUBLIC_REPEAT','ADMIN_MANUAL')),
    CONSTRAINT ck_quote_follow_up_count CHECK (follow_up_count >= 0),
    CONSTRAINT ck_quote_repeat_presence CHECK ((creation_method = 'PUBLIC_REPEAT' AND repeat_verification_id IS NOT NULL)
        OR (creation_method IN ('PUBLIC_FIRST','ADMIN_MANUAL') AND repeat_verification_id IS NULL)),
    CONSTRAINT ck_quote_admin_actor CHECK (creation_method <> 'ADMIN_MANUAL' OR created_by IS NOT NULL),
    CONSTRAINT ck_quote_failed_reason CHECK (status <> 'FAILED' OR nullif(btrim(lost_reason), '') IS NOT NULL),
    CONSTRAINT ck_quote_success_time CHECK ((status = 'SUCCESS') = (converted_at IS NOT NULL))
);


CREATE TABLE quote_request_events (
    id uuid PRIMARY KEY,
    quote_request_id uuid NOT NULL REFERENCES quote_requests(id) ON DELETE RESTRICT,
    event_type varchar(32) NOT NULL,
    detail varchar(4000),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT ck_quote_event_type CHECK (nullif(btrim(event_type), '') IS NOT NULL),
    CONSTRAINT ck_quote_event_immutable_audit CHECK (updated_at = created_at AND updated_by IS NOT DISTINCT FROM created_by)
);
--rollback DROP TABLE quote_request_events;
--rollback DROP TABLE quote_requests;
--rollback DROP TABLE otp_challenges;
--rollback DROP TABLE consent_log;
--rollback DROP TABLE leads;
--rollback DROP TABLE login_activity;
--rollback DROP TABLE user_roles;
--rollback DROP TABLE users;
--rollback DROP TABLE roles;
