package com.example.demo.note;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

@RestController
public class NoteController {
  private final NoteRepo repo;
  public NoteController(NoteRepo repo){ this.repo = repo; }

  @GetMapping("/api/notes")
  public List<Note> notes(){ return repo.findAll(); }
}
