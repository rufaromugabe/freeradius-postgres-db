--
-- Seed data for FreeRADIUS PostgreSQL database
--
-- Insert sample users
INSERT INTO
  radcheck (username, attribute, op, value)
VALUES
  ('bob', 'Cleartext-Password', ':=', 'test'),
  (
    'alice',
    'Cleartext-Password',
    ':=',
    'password123'
  ),
  (
    'guest1',
    'Cleartext-Password',
    ':=',
    'guestpass'
  ),
  ('admin', 'Cleartext-Password', ':=', 'admin123');
-- Reply attributes for alice (VLAN assignment for 802.1X)
INSERT INTO
  radreply (username, attribute, op, value)
VALUES
  ('alice', 'Tunnel-Type', ':=', 'VLAN'),
  ('alice', 'Tunnel-Medium-Type', ':=', 'IEEE-802'),
  ('alice', 'Tunnel-Private-Group-Id', ':=', '100'),
  ('alice', 'Reply-Message', '=', 'Welcome Alice');
-- Reply attributes for admin (different VLAN)
INSERT INTO
  radreply (username, attribute, op, value)
VALUES
  ('admin', 'Tunnel-Type', ':=', 'VLAN'),
  ('admin', 'Tunnel-Medium-Type', ':=', 'IEEE-802'),
  ('admin', 'Tunnel-Private-Group-Id', ':=', '200'),
  (
    'admin',
    'Reply-Message',
    '=',
    'Welcome Administrator'
  );
-- Create sample groups
  -- Guest group with time limits
INSERT INTO
  radgroupcheck (groupname, attribute, op, value)
VALUES
  ('guest', 'Auth-Type', ':=', 'Accept');
INSERT INTO
  radgroupreply (groupname, attribute, op, value)
VALUES
  ('guest', 'Session-Timeout', ':=', '3600'),
  ('guest', 'Idle-Timeout', ':=', '600'),
  ('guest', 'Reply-Message', '=', 'Welcome Guest');
-- Employee group with longer session time
INSERT INTO
  radgroupcheck (groupname, attribute, op, value)
VALUES
  ('employees', 'Auth-Type', ':=', 'Accept');
INSERT INTO
  radgroupreply (groupname, attribute, op, value)
VALUES
  ('employees', 'Session-Timeout', ':=', '28800'),
  ('employees', 'Idle-Timeout', ':=', '1800'),
  (
    'employees',
    'Reply-Message',
    '=',
    'Welcome Employee'
  );
-- VIP group with no time limits
INSERT INTO
  radgroupcheck (groupname, attribute, op, value)
VALUES
  ('vip', 'Auth-Type', ':=', 'Accept');
INSERT INTO
  radgroupreply (groupname, attribute, op, value)
VALUES
  ('vip', 'Reply-Message', '=', 'Welcome VIP User');
-- Assign users to groups
INSERT INTO
  radusergroup (username, groupname, priority)
VALUES
  ('guest1', 'guest', 1),
  ('bob', 'employees', 1),
  ('alice', 'vip', 1);
-- Sample NAS (Network Access Server) entries
INSERT INTO
  nas (
    nasname,
    shortname,
    type,
    secret,
    description,
    require_ma,
    limit_proxy_state
  )
VALUES
  (
    '172.18.0.0/16',
    'dockernet',
    'other',
    'testing123',
    'Docker network',
    'no',
    'auto'
  ),
  (
    '127.0.0.1',
    'localhost',
    'other',
    'testing123',
    'Localhost for testing',
    'no',
    'auto'
  );
-- You can add more NAS devices here:
  -- Example WiFi Access Point
  -- INSERT INTO nas (nasname, shortname, type, secret, description, require_ma) VALUES
  -- ('192.168.1.10', 'wifi-ap-01', 'cisco', 'your_secret_here', 'Main Office WiFi AP', 'yes');
  -- Example VPN Server
  -- INSERT INTO nas (nasname, shortname, type, secret, description, require_ma) VALUES
  -- ('192.168.1.20', 'vpn-01', 'other', 'your_secret_here', 'VPN Gateway', 'yes');
  -- Example Network Switch
  -- INSERT INTO nas (nasname, shortname, type, secret, description, require_ma) VALUES
  -- ('192.168.1.30', 'switch-01', 'other', 'your_secret_here', 'Core Switch 802.1X', 'yes');
  -- Healthcheck user (for Docker health checks)
INSERT INTO
  radcheck (username, attribute, op, value)
VALUES
  (
    'healthcheck',
    'Cleartext-Password',
    ':=',
    'healthcheck'
  );
INSERT INTO
  radreply (username, attribute, op, value)
VALUES
  (
    'healthcheck',
    'Reply-Message',
    '=',
    'Health check OK'
  );