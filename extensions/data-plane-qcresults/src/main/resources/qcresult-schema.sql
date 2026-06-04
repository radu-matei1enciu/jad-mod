--
--  Copyright (c) 2025 Metaform Systems, Inc.
--
--  This program and the accompanying materials are made available under the
--  terms of the Apache License, Version 2.0 which is available at
--  https://www.apache.org/licenses/LICENSE-2.0
--
--  SPDX-License-Identifier: Apache-2.0
--
--  Contributors:
--       Metaform Systems, Inc. - initial API and implementation
--

-- THIS SCHEMA HAS BEEN WRITTEN AND TESTED ONLY FOR POSTGRES

CREATE TABLE IF NOT EXISTS qc_result (
    id               VARCHAR PRIMARY KEY,
    batch_id         VARCHAR NOT NULL,
    product          VARCHAR NOT NULL,
    test             VARCHAR NOT NULL,
    result           VARCHAR NOT NULL,
    specification    VARCHAR NOT NULL,
    status           VARCHAR NOT NULL,
    approved_at      VARCHAR NOT NULL
);