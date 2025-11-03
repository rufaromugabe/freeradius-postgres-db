--
-- FreeRADIUS PostgreSQL Database Schema
-- Official schema from FreeRADIUS distribution
--

--
-- Table structure for table 'radacct'
--
CREATE TABLE IF NOT EXISTS radacct (
	radacctid		bigserial PRIMARY KEY,
	acctsessionid		text NOT NULL,
	acctuniqueid		text NOT NULL UNIQUE,
	username		text,
	groupname		text,
	realm			text,
	nasipaddress		inet NOT NULL,
	nasportid		text,
	nasporttype		text,
	acctstarttime		timestamp with time zone,
	acctupdatetime		timestamp with time zone,
	acctstoptime		timestamp with time zone,
	acctinterval		bigint,
	acctsessiontime		bigint,
	acctauthentic		text,
	connectinfo_start	text,
	connectinfo_stop	text,
	acctinputoctets		bigint,
	acctoutputoctets	bigint,
	calledstationid		text,
	callingstationid	text,
	acctterminatecause	text,
	servicetype		text,
	framedprotocol		text,
	framedipaddress		inet,
	framedipv6address	inet,
	framedipv6prefix	inet,
	framedinterfaceid	text,
	delegatedipv6prefix	inet,
	class 			text
);

-- For use by update-, stop- and simul_* queries
CREATE INDEX radacct_active_session_idx ON radacct (acctuniqueid) WHERE acctstoptime IS NULL;

-- For use by onoff-
CREATE INDEX radacct_bulk_close ON radacct (nasipaddress, acctstarttime) WHERE acctstoptime IS NULL;

-- For use by cleanup scripts
CREATE INDEX radacct_bulk_timeout ON radacct (acctstoptime NULLS FIRST, acctupdatetime);

-- For common statistic queries:
CREATE INDEX radacct_start_user_idx ON radacct (acctstarttime, username);

--
-- Table structure for table 'radcheck'
--
CREATE TABLE radcheck (
	id			serial PRIMARY KEY,
	username		text NOT NULL DEFAULT '',
	attribute		text NOT NULL DEFAULT '',
	op			VARCHAR(2) NOT NULL DEFAULT '==',
	value			text NOT NULL DEFAULT ''
);
CREATE INDEX radcheck_username ON radcheck (username, attribute);

--
-- Table structure for table 'radgroupcheck'
--
CREATE TABLE radgroupcheck (
	id			serial PRIMARY KEY,
	groupname		text NOT NULL DEFAULT '',
	attribute		text NOT NULL DEFAULT '',
	op			VARCHAR(2) NOT NULL DEFAULT '==',
	value			text NOT NULL DEFAULT ''
);
CREATE INDEX radgroupcheck_groupname ON radgroupcheck (groupname, attribute);

--
-- Table structure for table 'radgroupreply'
--
CREATE TABLE radgroupreply (
	id			serial PRIMARY KEY,
	groupname		text NOT NULL DEFAULT '',
	attribute		text NOT NULL DEFAULT '',
	op			VARCHAR(2) NOT NULL DEFAULT '=',
	value			text NOT NULL DEFAULT ''
);
CREATE INDEX radgroupreply_groupname ON radgroupreply (groupname, attribute);

--
-- Table structure for table 'radreply'
--
CREATE TABLE radreply (
	id			serial PRIMARY KEY,
	username		text NOT NULL DEFAULT '',
	attribute		text NOT NULL DEFAULT '',
	op			VARCHAR(2) NOT NULL DEFAULT '=',
	value			text NOT NULL DEFAULT ''
);
CREATE INDEX radreply_username ON radreply (username, attribute);

--
-- Table structure for table 'radusergroup'
--
CREATE TABLE radusergroup (
	id			serial PRIMARY KEY,
	username		text NOT NULL DEFAULT '',
	groupname		text NOT NULL DEFAULT '',
	priority		integer NOT NULL DEFAULT 0
);
CREATE INDEX radusergroup_username ON radusergroup (username);

--
-- Table structure for table 'radpostauth'
--
CREATE TABLE radpostauth (
	id			bigserial PRIMARY KEY,
	username		text NOT NULL,
	pass			text,
	reply			text,
	calledstationid		text,
	callingstationid	text,
	authdate		timestamp with time zone NOT NULL DEFAULT now(),
	class			text
);

--
-- Table structure for table 'nas'
--
CREATE TABLE nas (
	id			serial PRIMARY KEY,
	nasname			text NOT NULL,
	shortname		text NOT NULL,
	type			text NOT NULL DEFAULT 'other',
	ports			integer,
	secret			text NOT NULL,
	server			text,
	community		text,
	description		text,
	require_ma		text NOT NULL DEFAULT 'auto',
	limit_proxy_state	text NOT NULL DEFAULT 'auto'
);
CREATE INDEX nas_nasname ON nas (nasname);

--
-- Table structure for table 'nasreload'
--
CREATE TABLE IF NOT EXISTS nasreload (
	nasipaddress		inet PRIMARY KEY,
	reloadtime		timestamp with time zone NOT NULL
);

-- Create views for easier querying
CREATE OR REPLACE VIEW user_sessions AS
SELECT 
    username,
    nasipaddress,
    acctsessionid,
    acctstarttime,
    acctstoptime,
    acctsessiontime,
    acctinputoctets,
    acctoutputoctets,
    acctterminatecause
FROM radacct
WHERE acctstoptime IS NULL;

CREATE OR REPLACE VIEW auth_log AS
SELECT 
    username,
    reply,
    authdate,
    calledstationid,
    callingstationid
FROM radpostauth
ORDER BY authdate DESC
LIMIT 100;

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO radius;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO radius;