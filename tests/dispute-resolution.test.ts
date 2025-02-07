import { describe, it, beforeEach, expect } from "vitest"

describe("dispute-resolution", () => {
  let contract: any
  let disputes: Map<number, any>
  
  beforeEach(() => {
    disputes = new Map()
    contract = {
      fileDispute: (marketId: number, reason: string) => {
        if (disputes.has(marketId)) {
          throw new Error("ERR_ALREADY_DISPUTED")
        }
        disputes.set(marketId, {
          disputer: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
          reason: reason,
          status: "pending",
          resolution: null,
        })
        return { success: true }
      },
      resolveDispute: (marketId: number, resolution: string) => {
        if (!disputes.has(marketId)) {
          throw new Error("ERR_NOT_FOUND")
        }
        const dispute = disputes.get(marketId)
        dispute.status = "resolved"
        dispute.resolution = resolution
        return { success: true }
      },
      getDispute: (marketId: number) => {
        return disputes.get(marketId) || null
      },
    }
  })
  
  describe("file-dispute", () => {
    it("should file a dispute for a market", () => {
      const result = contract.fileDispute(1, "Incorrect outcome")
      expect(result.success).toBe(true)
    })
    
    it("should fail when filing a dispute for an already disputed market", () => {
      contract.fileDispute(1, "Incorrect outcome")
      expect(() => contract.fileDispute(1, "New dispute")).toThrow("ERR_ALREADY_DISPUTED")
    })
  })
  
  describe("resolve-dispute", () => {
    it("should resolve a dispute", () => {
      contract.fileDispute(1, "Incorrect outcome")
      const result = contract.resolveDispute(1, "Dispute resolved in favor of the market outcome")
      expect(result.success).toBe(true)
    })
    
    it("should fail when resolving a non-existent dispute", () => {
      expect(() => contract.resolveDispute(2, "Resolution")).toThrow("ERR_NOT_FOUND")
    })
  })
  
  describe("get-dispute", () => {
    it("should return dispute details", () => {
      contract.fileDispute(1, "Incorrect outcome")
      const result = contract.getDispute(1)
      expect(result.disputer).toBe("ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM")
      expect(result.reason).toBe("Incorrect outcome")
      expect(result.status).toBe("pending")
      expect(result.resolution).toBeNull()
    })
    
    it("should return null for a non-existent dispute", () => {
      const result = contract.getDispute(2)
      expect(result).toBeNull()
    })
  })
})

