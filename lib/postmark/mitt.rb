module Postmark
  class Mitt
    def initialize(json)
      @raw = json
      @source = MultiJson.decode(json)
    end

    attr_reader :raw, :source

    def inspect
      "<Postmark::Mitt: #{message_id}>"
    end

    def subject
      source["Subject"]
    end

    def from
        source["From"].gsub('"', '')
    end    

    def from_email
      source["FromFull"]["Email"]
      #if match = from.match(/^.+<(.+)>$/)
      #  match[1].strip
      #else
      #  from
      #end
    end

    def from_name
      #if match = from.match(/(^.+)<.+>$/)
      #  match[1].strip
      #else
      #  from
      #end
      source["FromFull"]["Name"]      
    end

    def to
      source["To"]
    end
    
    def to_email
      source["ToFull"][0]["Email"]
    end
    
    def to_name
      source["ToFull"][0]["Name"]    
    end

    def bcc
      source["Bcc"]
    end

    def cc
      source["Cc"]
    end

    def cc_email
      source["CcFull"][0]["Email"]
    end

    def cc_email
      source["CcFull"][0]["Name"]
    end

    def reply_to
      source["ReplyTo"]
    end

    def html_body
      source["HtmlBody"]
    end

    def text_body
      source["TextBody"]
    end

    def mailbox_hash
      source["MailboxHash"]
    end

    def tag
      source["Tag"]
    end

    def headers
      @headers ||= source["Headers"].inject({}){|hash,obj| hash[obj["Name"]] = obj["Value"]; hash}
    end

    def message_id
      source["MessageID"]
    end

    def attachments
      @attachments ||= begin
        raw_attachments = source["Attachments"] || []
        AttachmentsArray.new(raw_attachments.map{|a| Attachment.new(a)})
      end
    end

    def has_attachments?
      !attachments.empty?
    end

    class Attachment
      def initialize(attachment_source)
        @source = attachment_source
      end
      attr_accessor :source

      def content_type
        source["ContentType"]
      end

      def file_name
        source["Name"]
      end

      def read
        tempfile = MittTempfile.new(file_name, content_type)
        tempfile.write(Base64.decode64(source["Content"]))
        tempfile
      end

      def size
        source["ContentLength"]
      end
    end

    class AttachmentsArray < Array
      def sorted
        @sorted ||= self.sort{|x,y|x.size <=> y.size}
      end

      def largest
        sorted.last
      end

      def smallest
        sorted.first
      end
    end
  end

  class MittTempfile < Tempfile
    def initialize(basename, content_type, tmpdir=Dir::tmpdir)
      super(basename, tmpdir)
      @basename = basename
      @content_type = content_type
    end

    # The content type of the "uploaded" file
    attr_accessor :content_type

    def original_filename
      @basename || File.basename(path)
    end
  end
end
