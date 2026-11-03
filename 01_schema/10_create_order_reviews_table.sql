
-- Project: Customer Churn & Retention Intelligence
-- Purpose: Create the Olist order reviews table

CREATE TABLE IF NOT EXISTS olist.order_reviews (
    review_record_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    review_id VARCHAR(32),
    order_id VARCHAR(32) NOT NULL,
    review_score SMALLINT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,

    CONSTRAINT fk_order_reviews_order
        FOREIGN KEY (order_id)
        REFERENCES olist.orders(order_id),

    CONSTRAINT chk_review_score
        CHECK (review_score BETWEEN 1 AND 5)
);
