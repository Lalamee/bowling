package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;

@Entity
@Table(name = "supplier_reviews")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class SupplierReview {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "review_id")
    private Long reviewId;

    @Column(name = "supplier_id")
    private Long supplierId;

    @Column(name = "club_id")
    private Long clubId;

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "rating")
    private Integer rating;

    @Column(name = "comment")
    private String comment;

    @Column(name = "review_date")
    private LocalDateTime reviewDate;

    @Column(name = "is_complaint")
    private Boolean isComplaint;

    @Column(name = "complaint_resolved")
    private Boolean complaintResolved;
}

