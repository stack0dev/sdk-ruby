# frozen_string_literal: true

module Stack0
  module Mail
    # Sequences client for managing automated email sequences
    class Sequences
      def initialize(http)
        @http = http
      end

      # List all sequences
      #
      # @param environment [String, nil] Environment filter
      # @param limit [Integer, nil] Maximum number of results
      # @param offset [Integer, nil] Offset for pagination
      # @param search [String, nil] Search query
      # @param status [String, nil] Sequence status filter
      # @param trigger_type [String, nil] Trigger type filter
      # @return [Hash] Paginated list of sequences
      def list(environment: nil, limit: nil, offset: nil, search: nil, status: nil, trigger_type: nil)
        params = {}
        params[:environment] = environment if environment
        params[:limit] = limit if limit
        params[:offset] = offset if offset
        params[:search] = search if search
        params[:status] = status if status
        params[:triggerType] = trigger_type if trigger_type

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.get("/mail/sequences#{query}")
      end

      # Get a sequence by ID with nodes and connections
      #
      # @param id [String] Sequence ID
      # @return [Hash] Sequence with nodes and connections
      def get(id)
        @http.get("/mail/sequences/#{id}")
      end

      # Create a new sequence
      #
      # @param name [String] Sequence name
      # @param trigger_type [String] Trigger type
      # @param environment [String, nil] Environment
      # @param description [String, nil] Sequence description
      # @param trigger_frequency [String, nil] Trigger frequency
      # @param trigger_config [Hash, nil] Trigger configuration
      # @param audience_filter_id [String, nil] Audience filter ID
      # @return [Hash] Created sequence
      def create(name:, trigger_type:, environment: nil, description: nil,
                 trigger_frequency: nil, trigger_config: nil, audience_filter_id: nil)
        body = { name: name, triggerType: trigger_type }
        body[:environment] = environment if environment
        body[:description] = description if description
        body[:triggerFrequency] = trigger_frequency if trigger_frequency
        body[:triggerConfig] = trigger_config if trigger_config
        body[:audienceFilterId] = audience_filter_id if audience_filter_id

        @http.post("/mail/sequences", body)
      end

      # Update a sequence
      #
      # @param id [String] Sequence ID
      # @param name [String, nil] Sequence name
      # @param description [String, nil] Sequence description
      # @param trigger_type [String, nil] Trigger type
      # @param trigger_frequency [String, nil] Trigger frequency
      # @param trigger_config [Hash, nil] Trigger configuration
      # @param audience_filter_id [String, nil] Audience filter ID
      # @return [Hash] Updated sequence
      def update(id:, name: nil, description: nil, trigger_type: nil,
                 trigger_frequency: nil, trigger_config: nil, audience_filter_id: nil)
        body = {}
        body[:name] = name if name
        body[:description] = description if description
        body[:triggerType] = trigger_type if trigger_type
        body[:triggerFrequency] = trigger_frequency if trigger_frequency
        body[:triggerConfig] = trigger_config if trigger_config
        body[:audienceFilterId] = audience_filter_id if audience_filter_id

        @http.put("/mail/sequences/#{id}", body)
      end

      # Delete a sequence
      #
      # @param id [String] Sequence ID
      # @return [Hash] Success response
      def delete(id)
        @http.delete("/mail/sequences/#{id}")
      end

      # Publish (activate) a sequence
      #
      # @param id [String] Sequence ID
      # @return [Hash] Success response
      def publish(id)
        @http.post("/mail/sequences/#{id}/publish", {})
      end

      # Pause an active sequence
      #
      # @param id [String] Sequence ID
      # @return [Hash] Success response
      def pause(id)
        @http.post("/mail/sequences/#{id}/pause", {})
      end

      # Resume a paused sequence
      #
      # @param id [String] Sequence ID
      # @return [Hash] Success response
      def resume(id)
        @http.post("/mail/sequences/#{id}/resume", {})
      end

      # Archive a sequence
      #
      # @param id [String] Sequence ID
      # @return [Hash] Success response
      def archive(id)
        @http.post("/mail/sequences/#{id}/archive", {})
      end

      # Duplicate a sequence
      #
      # @param id [String] Sequence ID
      # @param name [String, nil] New name for duplicated sequence
      # @return [Hash] Duplicated sequence
      def duplicate(id, name: nil)
        @http.post("/mail/sequences/#{id}/duplicate", { name: name })
      end

      # Create a node in a sequence
      #
      # @param sequence_id [String] Sequence ID
      # @param node_type [String] Node type
      # @param name [String] Node name
      # @param position_x [Integer] X position
      # @param position_y [Integer] Y position
      # @param sort_order [Integer, nil] Sort order
      # @param config [Hash, nil] Node configuration
      # @return [Hash] Created node
      def create_node(sequence_id:, node_type:, name:, position_x:, position_y:, sort_order: nil, config: nil)
        body = {
          nodeType: node_type,
          name: name,
          positionX: position_x,
          positionY: position_y
        }
        body[:sortOrder] = sort_order if sort_order
        body[:config] = config if config

        @http.post("/mail/sequences/#{sequence_id}/nodes", body)
      end

      # Update a node
      #
      # @param sequence_id [String] Sequence ID
      # @param node_id [String] Node ID
      # @param name [String, nil] Node name
      # @param position_x [Integer, nil] X position
      # @param position_y [Integer, nil] Y position
      # @param sort_order [Integer, nil] Sort order
      # @param config [Hash, nil] Node configuration
      # @return [Hash] Updated node
      def update_node(sequence_id:, node_id:, name: nil, position_x: nil, position_y: nil, sort_order: nil, config: nil)
        body = {}
        body[:name] = name if name
        body[:positionX] = position_x if position_x
        body[:positionY] = position_y if position_y
        body[:sortOrder] = sort_order if sort_order
        body[:config] = config if config

        @http.put("/mail/sequences/#{sequence_id}/nodes/#{node_id}", body)
      end

      # Update node position
      #
      # @param sequence_id [String] Sequence ID
      # @param node_id [String] Node ID
      # @param position_x [Integer] X position
      # @param position_y [Integer] Y position
      # @return [Hash] Updated node
      def update_node_position(sequence_id:, node_id:, position_x:, position_y:)
        @http.put("/mail/sequences/#{sequence_id}/nodes/#{node_id}/position", {
          positionX: position_x,
          positionY: position_y
        })
      end

      # Delete a node
      #
      # @param sequence_id [String] Sequence ID
      # @param node_id [String] Node ID
      # @return [Hash] Success response
      def delete_node(sequence_id:, node_id:)
        @http.delete("/mail/sequences/#{sequence_id}/nodes/#{node_id}")
      end

      # Set email node content
      #
      # @param sequence_id [String] Sequence ID
      # @param node_id [String] Node ID
      # @param subject [String, nil] Email subject
      # @param preview_text [String, nil] Preview text
      # @param html [String, nil] HTML content
      # @param text [String, nil] Plain text content
      # @param template_id [String, nil] Template ID
      # @param maily_json [Hash, nil] Maily JSON data
      # @param from_email [String, nil] Sender email
      # @param from_name [String, nil] Sender name
      # @param reply_to [String, nil] Reply-to address
      # @return [Hash] Updated node
      def set_node_email(sequence_id:, node_id:, subject: nil, preview_text: nil, html: nil, text: nil,
                         template_id: nil, maily_json: nil, from_email: nil, from_name: nil, reply_to: nil)
        body = {}
        body[:subject] = subject if subject
        body[:previewText] = preview_text if preview_text
        body[:html] = html if html
        body[:text] = text if text
        body[:templateId] = template_id if template_id
        body[:mailyJson] = maily_json if maily_json
        body[:fromEmail] = from_email if from_email
        body[:fromName] = from_name if from_name
        body[:replyTo] = reply_to if reply_to

        @http.put("/mail/sequences/#{sequence_id}/nodes/#{node_id}/email", body)
      end

      # Set timer node configuration
      #
      # @param sequence_id [String] Sequence ID
      # @param node_id [String] Node ID
      # @param delay_amount [Integer] Delay amount
      # @param delay_unit [String] Delay unit (minutes, hours, days, weeks)
      # @param wait_until_time [String, nil] Wait until specific time
      # @param wait_until_timezone [String, nil] Timezone
      # @return [Hash] Updated node
      def set_node_timer(sequence_id:, node_id:, delay_amount:, delay_unit:, wait_until_time: nil, wait_until_timezone: nil)
        body = {
          delayAmount: delay_amount,
          delayUnit: delay_unit
        }
        body[:waitUntilTime] = wait_until_time if wait_until_time
        body[:waitUntilTimezone] = wait_until_timezone if wait_until_timezone

        @http.put("/mail/sequences/#{sequence_id}/nodes/#{node_id}/timer", body)
      end

      # Set filter node configuration
      #
      # @param sequence_id [String] Sequence ID
      # @param node_id [String] Node ID
      # @param conditions [Hash] Filter conditions
      # @param non_match_action [String, nil] Action for non-matches
      # @return [Hash] Updated node
      def set_node_filter(sequence_id:, node_id:, conditions:, non_match_action: nil)
        body = { conditions: conditions }
        body[:nonMatchAction] = non_match_action if non_match_action

        @http.put("/mail/sequences/#{sequence_id}/nodes/#{node_id}/filter", body)
      end

      # Set branch node configuration
      #
      # @param sequence_id [String] Sequence ID
      # @param node_id [String] Node ID
      # @param branches [Array<Hash>] Branch definitions
      # @param has_default_branch [Boolean, nil] Whether to have a default branch
      # @return [Hash] Updated node
      def set_node_branch(sequence_id:, node_id:, branches:, has_default_branch: nil)
        body = { branches: branches }
        body[:hasDefaultBranch] = has_default_branch unless has_default_branch.nil?

        @http.put("/mail/sequences/#{sequence_id}/nodes/#{node_id}/branch", body)
      end

      # Set experiment node configuration
      #
      # @param sequence_id [String] Sequence ID
      # @param node_id [String] Node ID
      # @param variants [Array<Hash>] Experiment variants
      # @param sample_size [Integer, nil] Sample size
      # @return [Hash] Updated node
      def set_node_experiment(sequence_id:, node_id:, variants:, sample_size: nil)
        body = { variants: variants }
        body[:sampleSize] = sample_size if sample_size

        @http.put("/mail/sequences/#{sequence_id}/nodes/#{node_id}/experiment", body)
      end

      # Create a connection between nodes
      #
      # @param sequence_id [String] Sequence ID
      # @param source_node_id [String] Source node ID
      # @param target_node_id [String] Target node ID
      # @param connection_type [String, nil] Connection type
      # @param label [String, nil] Connection label
      # @return [Hash] Created connection
      def create_connection(sequence_id:, source_node_id:, target_node_id:, connection_type: nil, label: nil)
        body = {
          sourceNodeId: source_node_id,
          targetNodeId: target_node_id
        }
        body[:connectionType] = connection_type if connection_type
        body[:label] = label if label

        @http.post("/mail/sequences/#{sequence_id}/connections", body)
      end

      # Delete a connection
      #
      # @param sequence_id [String] Sequence ID
      # @param connection_id [String] Connection ID
      # @return [Hash] Success response
      def delete_connection(sequence_id:, connection_id:)
        @http.delete("/mail/sequences/#{sequence_id}/connections/#{connection_id}")
      end

      # List contacts in a sequence
      #
      # @param sequence_id [String] Sequence ID
      # @param limit [Integer, nil] Maximum number of results
      # @param offset [Integer, nil] Offset for pagination
      # @param status [String, nil] Entry status filter
      # @return [Hash] Paginated list of entries
      def list_entries(sequence_id:, limit: nil, offset: nil, status: nil)
        params = {}
        params[:limit] = limit if limit
        params[:offset] = offset if offset
        params[:status] = status if status

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.get("/mail/sequences/#{sequence_id}/entries#{query}")
      end

      # Add a contact to a sequence
      #
      # @param sequence_id [String] Sequence ID
      # @param contact_id [String] Contact ID
      # @return [Hash] Created entry
      def add_contact(sequence_id:, contact_id:)
        @http.post("/mail/sequences/#{sequence_id}/add-contact", { contactId: contact_id })
      end

      # Remove a contact from a sequence
      #
      # @param sequence_id [String] Sequence ID
      # @param entry_id [String] Entry ID
      # @param reason [String, nil] Removal reason
      # @return [Hash] Success response
      def remove_contact(sequence_id:, entry_id:, reason: nil)
        body = { entryId: entry_id }
        body[:reason] = reason if reason

        @http.post("/mail/sequences/#{sequence_id}/remove-contact", body)
      end

      # Get sequence analytics
      #
      # @param id [String] Sequence ID
      # @return [Hash] Sequence analytics
      def get_analytics(id)
        @http.get("/mail/sequences/#{id}/analytics")
      end
    end
  end
end
