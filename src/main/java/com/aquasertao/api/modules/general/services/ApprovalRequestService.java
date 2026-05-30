package com.aquasertao.api.modules.general.services;

import com.aquasertao.api.modules.general.dtos.ApprovalRequestReqDTO;
import com.aquasertao.api.modules.general.dtos.ApprovalRequestResDTO;
import com.aquasertao.api.modules.general.models.ApprovalRequest;
import com.aquasertao.api.modules.general.repositories.ApprovalRequestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ApprovalRequestService {

    private final ApprovalRequestRepository approvalRequestRepository;

    public ApprovalRequestResDTO createRequest(ApprovalRequestReqDTO reqDTO) {
        ApprovalRequest request = ApprovalRequest.builder()
                .farmId(reqDTO.getFarmId())
                .requesterId(reqDTO.getRequesterId())
                .requestedAction(reqDTO.getRequestedAction())
                .status("PENDING")
                .build();

        ApprovalRequest savedRequest = approvalRequestRepository.save(request);
        return mapToDTO(savedRequest);
    }

    public ApprovalRequestResDTO resolveRequest(UUID requestId, String newStatus) {
        ApprovalRequest request = approvalRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Request not found"));
                
        request.setStatus(newStatus);
        ApprovalRequest updatedRequest = approvalRequestRepository.save(request);
        return mapToDTO(updatedRequest);
    }

    public Page<ApprovalRequestResDTO> getRequestsByFarmId(UUID farmId, Pageable pageable) {
        Page<ApprovalRequest> requestsPage = approvalRequestRepository.findByFarmId(farmId, pageable);
        return requestsPage.map(this::mapToDTO);
    }

    private ApprovalRequestResDTO mapToDTO(ApprovalRequest request) {
        return ApprovalRequestResDTO.builder()
                .id(request.getId())
                .farmId(request.getFarmId())
                .requesterId(request.getRequesterId())
                .requestedAction(request.getRequestedAction())
                .status(request.getStatus())
                .requestDate(request.getRequestDate())
                .build();
    }
}
