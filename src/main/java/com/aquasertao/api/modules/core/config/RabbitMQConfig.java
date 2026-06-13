package com.aquasertao.api.modules.core.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    public static final String QUEUE_NAME = "supplier.approved.queue";
    public static final String EXCHANGE_NAME = "supplier.exchange";
    public static final String ROUTING_KEY = "supplier.approved";

    @Bean
    public Queue supplierQueue() {
        return new Queue(QUEUE_NAME, true);
    }

    @Bean
    public TopicExchange supplierExchange() {
        return new TopicExchange(EXCHANGE_NAME);
    }

    @Bean
    public Binding supplierBinding(Queue supplierQueue, TopicExchange supplierExchange) {
        return BindingBuilder.bind(supplierQueue).to(supplierExchange).with(ROUTING_KEY);
    }

    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
