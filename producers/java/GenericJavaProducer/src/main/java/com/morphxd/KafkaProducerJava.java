package com.morphxd;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Properties;

public class KafkaProducerJava {
    private static final Logger log = LoggerFactory.getLogger(KafkaProducerJava.class);

    public static void main(String[] args) {
        // Read configuration from Environment Variables (Defaults for local dev)
        String bootstrapServers = System.getenv().getOrDefault("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092");
        String topic = System.getenv().getOrDefault("KAFKA_TOPIC", "JavaConsumerTopic");

        log.info("Starting Kafka Producer. Connecting to {} and publishing to {}", bootstrapServers, topic);

        // Configure Producer Properties
        Properties properties = new Properties();
        properties.setProperty(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        properties.setProperty(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        properties.setProperty(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        
        // Reliability/Durability configurations
        properties.setProperty(ProducerConfig.ACKS_CONFIG, "all");
        properties.setProperty(ProducerConfig.RETRIES_CONFIG, Integer.toString(Integer.MAX_VALUE));
        properties.setProperty(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, "true");

        KafkaProducer<String, String> producer = new KafkaProducer<>(properties);

        // Register Graceful Shutdown Hook 
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            log.info("Shutdown signal received. Closing Kafka producer...");
            producer.flush();
            producer.close();
            log.info("Producer closed successfully.");
        }));

        // Produce messages
        try {
            for (int i = 0; i < 100; i++) {
                String key = "id_" + i;
                String value = "System event payload data " + i;

                ProducerRecord<String, String> record = new ProducerRecord<>(topic, key, value);

                // Asynchronous send with a callback
                producer.send(record, (metadata, exception) -> {
                    if (exception == null) {
                        log.info("Successfully produced message: Topic={} Partition={} Offset={} Timestamp={}",
                                metadata.topic(), metadata.partition(), metadata.offset(), metadata.timestamp());
                    } else {
                        log.error("Error producing message", exception);
                    }
                });

                // Simulate workload delay
                Thread.sleep(1000);
            }
        } catch (InterruptedException e) {
            log.error("Producer thread was interrupted", e);
            Thread.currentThread().interrupt();
        } finally {
            // Ensure flush and close if the loop finishes naturally
            producer.flush();
            producer.close();
        }
    }
}