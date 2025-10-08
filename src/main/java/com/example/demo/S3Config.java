package com.example.demo;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.client.config.ClientOverrideConfiguration;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;

import java.net.URI;

@Configuration
public class S3Config {
  @Value("${aws.endpoint:http://localhost:4566}")
  private String endpoint;

  @Value("${aws.region:eu-central-1}")
  private String region;

  @Bean
  public S3Client s3Client() {
    return S3Client.builder()
        .httpClientBuilder(UrlConnectionHttpClient.builder())
        .credentialsProvider(StaticCredentialsProvider.create(
            AwsBasicCredentials.create("test", "test")))
        .endpointOverride(URI.create(endpoint))
        .region(Region.of(region))
        .serviceConfiguration(S3Configuration.builder()
            .pathStyleAccessEnabled(true) // важно для LocalStack
            .build())
        .overrideConfiguration(ClientOverrideConfiguration.builder().build())
        .build();
  }
}
