ALTER TABLE billing_schema.subscription 
ADD COLUMN stripe_customer_id VARCHAR(255),
ADD COLUMN stripe_subscription_id VARCHAR(255),
ADD COLUMN stripe_checkout_session_id VARCHAR(255);
