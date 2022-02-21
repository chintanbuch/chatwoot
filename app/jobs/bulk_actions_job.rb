class BulkActionsJob < ApplicationJob
  queue_as :medium
  attr_accessor :records

  MODEL_TYPE = ['Conversation'].freeze

  def perform(account:, params:, user:)
    @account = account
    Current.user = user
    @params = params
    @records = records_to_updated
    bulk_update(params)
  end

  def bulk_update(params)
    bulk_remove_labels
    bulk_conversation_update(params)
  end

  def bulk_conversation_update(params)
    params = available_params(params)
    records.each do |conversation|
      bulk_add_labels(conversation)
      conversation.update(params) if params
    end
  end

  def bulk_remove_labels
    records.each do |conversation|
      remove_labels(conversation)
    end
  end

  def available_params(params)
    return unless params[:fields]

    params[:fields].delete_if { |_k, v| v.nil? }
  end

  def bulk_add_labels(conversation)
    conversation.add_labels(@params[:labels][:add]) if @params[:labels] && @params[:labels][:add]
  end

  def remove_labels(conversation)
    return unless @params[:labels] && @params[:labels][:remove]

    labels = conversation.label_list - @params[:labels][:remove]
    conversation.update(label_list: labels)
  end

  def records_to_updated
    current_model = @params[:type].camelcase.constantize
    return if MODEL_TYPE.include?(current_model)

    current_model&.where(account_id: @account.id, display_id: @params[:ids])
  end
end
