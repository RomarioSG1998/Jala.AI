CREATE TABLE ops_schema.mortality_record (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    tank_id UUID NOT NULL,
    quantity INTEGER NOT NULL,
    cause VARCHAR(255),
    record_date TIMESTAMP NOT NULL,
    CONSTRAINT fk_mortality_tank FOREIGN KEY (tank_id) REFERENCES ops_schema.tank (id) ON DELETE CASCADE
);
