package com.example.demo.bdd;

import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;

import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class StepDefs {
  @LocalServerPort int port;
  ResponseEntity<String> last;

  @When("I GET {string}")
  public void i_get(String path){
    var rt = new RestTemplate();
    last = rt.getForEntity("http://localhost:"+port+path, String.class);
  }

  @Then("response status is {int}")
  public void response_status_is(int code){
    assertEquals(code, last.getStatusCode().value());
  }
}
