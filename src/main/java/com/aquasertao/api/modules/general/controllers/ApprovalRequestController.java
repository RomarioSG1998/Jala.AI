package com.aquasertao.api.modules.general.controllers;

import com.aquasertao.api.modules.general.dtos.ApprovalRequestReqDTO;
import com.aquasertao.api.modules.general.dtos.ApprovalRequestResDTO;
import com.aquasertao.api.modules.general.services.ApprovalRequestService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/approvals")
@RequiredArgsConstructor
public class ApprovalRequestController {

    private final ApprovalRequestService approvalRequestService;

    @PostMapping
    public ResponseEntity<ApprovalRequestResDTO> createRequest(@RequestBody ApprovalRequestReqDTO reqDTO) {
        return ResponseEntity.ok(approvalRequestService.createRequest(reqDTO));
    }

    @PutMapping("/{requestId}/resolve")
    public ResponseEntity<ApprovalRequestResDTO> resolveRequest(
            @PathVariable UUID requestId,
            @RequestParam String status
    ) {
        return ResponseEntity.ok(approvalRequestService.resolveRequest(requestId, status));
    }

    @GetMapping("/farm/{farmId}")
    public ResponseEntity<Page<ApprovalRequestResDTO>> getRequestsByFarmId(
            @PathVariable UUID farmId,
            Pageable pageable
    ) {
        Page<ApprovalRequestResDTO> responsePage = approvalRequestService.getRequestsByFarmId(farmId, pageable);
        return ResponseEntity.ok(responsePage);
    }
}
