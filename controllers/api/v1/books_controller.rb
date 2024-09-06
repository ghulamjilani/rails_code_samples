# frozen_string_literal: true

module Api
  module V1
    class BooksController < ApplicationController
      include ResponseGeneratorConcern
      include ActiveStorage::SetCurrent
      include ImageUrlConcern
      before_action :authenticate_api_v1_user!
      before_action :set_book, only: %i[show update destroy]

      def index
        @books = params[:book_type].present? || params[:filter].present? ? get_filtered_books : get_all_books
        render_response(true, 'Books retrieved successfully', :ok, records_with_image_url(@books), @books)
      end

      def show
        render_response(true, 'Book retrieved successfully', :ok,
                        record_with_image_url(@book).as_json.merge({ authors: @book.authors, category: @book.category, slides: @book.slides.as_json(include: :slide_items), workspaces: @book.workspaces }))
      end

      def create
        @book = current_api_v1_user.books.new(book_params)
        unless @book.save
          return render_response(false, @book.errors.full_messages.to_sentence,
                                 :unprocessable_entity)
        end

        render_response(true, 'Book created successfully', :created, record_with_image_url(@book))
      end

      def update
        unless @book.update(book_params)
          return render_response(false, @book.errors.full_messages.to_sentence,
                                 :unprocessable_entity)
        end

        render_response(true, 'Book updated successfully', :ok,
                        record_with_image_url(@book).as_json.merge(slides: @book.slides.as_json(include: :slide_items)))
      end

      def upload_content
        @book = Book.find_by(id: params[:book_id].to_i)
        @book.book_content.attach(params[:file])

        if @book.save!
          render json: url_for(@book.book_content)
        else
          render json: nil
        end
      end

      def download_content
        @book = Book.find_by(id: params[:book_id].to_i)
        if @book.book_content.attached?
          render json: url_for(@book.book_content)
        else
          render json: :not_found
        end
      end

      def trash_book
        book = Book.find(params[:book_id])
        return render_response(false, 'Book not found', :not_found) if book.nil?

        return if Trash.exists?(user: current_api_v1_user, book:)

        @books = Trash.create(user: current_api_v1_user, book:)
        render_response(true, 'Book trashed successfully', :ok, @books)
      end

      def list_trashed_books
        @books = current_api_v1_user.trashed_books.page(params[:page])
        render_response(true, 'Books retrieved successfully', :ok, records_with_image_url(@books), @books)
      end

      def destroy
        @book.destroy
        render_response(true, 'Book deleted successfully', :ok)
      end

      def destroy_slide_item
        slide_item = SlideItem.find_by(id: params[:item_id])

        return render_response(false, 'Slide Item not found', :not_found) if slide_item.nil?

        return render_response(false, 'Could not delete slide item.', :unprocessable_entity) unless slide_item.destroy

        render_response(true, 'Slide Item deleted successfully!', :ok)
      end

      def stats
        books_count = current_api_v1_user.books.published.size
        render_response(true, 'Listing books stats', :ok, {books_count: books_count})
      end

      private

      def set_book
        @book = Book.includes(:authors, :category, [slides: :slide_items]).find_by_id(params[:id].to_i)
        render_response(false, 'Book not found', :not_found) if @book.nil?
      end

      def get_all_books
        current_api_v1_user.books.not_in_trash.page(params[:page])
      end

      def get_filtered_books
        books = if params[:workspace].present?
                  current_api_v1_user.workspaces.find_by(name: params[:workspace]).books.not_in_trash
                elsif current_api_v1_user.has_role?(:super_admin)
                  Book.all
                else
                  current_api_v1_user.books.not_in_trash
                end

        books = books.by_kind(params[:book_type]) if params[:book_type].present?
        books = books.by_status(params[:filter]) if params[:filter].present?
        books = books.by_name(params[:name]) if params[:filter].present? && params[:name].present?
        books = books.by_published_date(params[:from], params[:to]) if params[:from].present? && params[:to].present?

        books.page(params[:page])
      end

      def book_params
        params.require(:book).permit(
          :name, :description, :content, :kind, :image, :category_id, :user_id, :status,
          :content_type, :isbn, :published_date, :page_count, :edition, :cost_per_seat, :rejection_note,
          author_ids: [],
          workspace_ids: [],
          slides_attributes: [
            :id, :color, :display_order, :slide_category, :is_deleted, :_destroy,
            { slide_items_attributes: %i[
              id color content item_type layout _destroy
            ] }
          ]
        )
      end
    end
  end
end
