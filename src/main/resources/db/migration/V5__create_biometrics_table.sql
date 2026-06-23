CREATE TABLE ops_schema.biometrics_record (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    tank_id UUID NOT NULL,
    weight_g INTEGER NOT NULL,
    record_date DATE NOT NULL,
    CONSTRAINT fk_biometrics_tank FOREIGN KEY (tank_id) REFERENCES ops_schema.tank (id) ON DELETE CASCADE
);
