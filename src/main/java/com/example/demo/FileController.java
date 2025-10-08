package com.example.demo;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

import jakarta.servlet.http.HttpServletResponse; // <-- ВАЖНО: jakarta, не javax
import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/files")
public class FileController {

  private final S3Client s3;
  private static final String BUCKET = "demo-bucket";

  public FileController(S3Client s3) {
    this.s3 = s3;
    ensureBucket();
  }

  private void ensureBucket() {
    try {
      s3.headBucket(HeadBucketRequest.builder().bucket(BUCKET).build());
    } catch (S3Exception e) {
      boolean notFound = e.statusCode() == 404
          || (e.awsErrorDetails() != null
              && "NotFound".equalsIgnoreCase(e.awsErrorDetails().errorCode()));
      if (notFound) {
        s3.createBucket(CreateBucketRequest.builder().bucket(BUCKET).build());
      } else {
        throw e;
      }
    }
  }

  @GetMapping
  public List<String> list() {
    ListObjectsV2Response resp = s3.listObjectsV2(
        ListObjectsV2Request.builder().bucket(BUCKET).build());
    return resp.contents().stream().map(S3Object::key).toList();
  }

  @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  public String upload(@RequestPart("file") MultipartFile file) throws IOException {
    s3.putObject(
        PutObjectRequest.builder()
            .bucket(BUCKET)
            .key(file.getOriginalFilename())
            .contentType(file.getContentType())
            .build(),
        RequestBody.fromBytes(file.getBytes())
    );
    return "uploaded:" + file.getOriginalFilename();
  }

  @GetMapping("/{key}")
  public @ResponseBody byte[] download(@PathVariable String key, HttpServletResponse resp) {
    var bytesResp = s3.getObject(
        GetObjectRequest.builder().bucket(BUCKET).key(key).build(),
        software.amazon.awssdk.core.sync.ResponseTransformer.toBytes()
    );
    var meta = bytesResp.response();
    resp.setContentType(meta.contentType() == null ? "application/octet-stream" : meta.contentType());
    resp.setHeader("Content-Disposition", "attachment; filename=\"" + key + "\"");
    return bytesResp.asByteArray();
  }

  @DeleteMapping("/{key}")
  public String delete(@PathVariable String key) {
    s3.deleteObject(DeleteObjectRequest.builder().bucket(BUCKET).key(key).build());
    return "deleted:" + key;
  }
}

