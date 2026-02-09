# frozen_string_literal: true

module Stack0
  # Polling module for async operations
  # Provides utilities for waiting on long-running operations
  module Polling
    # Poll until an operation completes or times out
    #
    # @param initial_id [String] The ID of the resource to poll
    # @param get_method [Proc] A callable that fetches the resource by ID
    # @param completed_statuses [Array<String>] Statuses indicating completion
    # @param failed_statuses [Array<String>] Statuses indicating failure
    # @param poll_interval [Integer] Seconds between polls
    # @param timeout [Integer] Maximum seconds to wait
    # @return [Hash] The completed resource
    # @raise [Error] If the operation fails
    # @raise [TimeoutError] If the operation times out
    def poll_until_complete(
      initial_id:,
      get_method:,
      completed_statuses:,
      failed_statuses: ["failed"],
      poll_interval: 1,
      timeout: 60
    )
      start_time = Time.now

      loop do
        result = get_method.call(initial_id)
        status = result["status"] || result[:status]

        return result if completed_statuses.include?(status)

        if failed_statuses.include?(status)
          error_message = result["error"] || result[:error] || "Operation failed"
          raise Error, error_message
        end

        if Time.now - start_time > timeout
          raise TimeoutError, "Operation timed out after #{timeout} seconds"
        end

        sleep(poll_interval)
      end
    end
  end
end
