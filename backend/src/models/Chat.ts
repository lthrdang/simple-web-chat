import { Schema, model, Document, Types } from 'mongoose'
import { IUser } from './User'

export interface IMessage {
  sender: Types.ObjectId | IUser
  content: string
  readBy: Types.ObjectId[]
  createdAt: Date
}

export interface IChat extends Document {
  name: string
  isGroup: boolean
  participants: Types.ObjectId[] | IUser[]
  messages: IMessage[]
  lastMessage?: IMessage
  createdBy: Types.ObjectId | IUser
  createdAt: Date
  updatedAt: Date
}

const messageSchema = new Schema<IMessage>(
  {
    sender: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    content: {
      type: String,
      required: true,
    },
    readBy: [{
      type: Schema.Types.ObjectId,
      ref: 'User',
    }],
  },
  {
    timestamps: true,
  }
)

const chatSchema = new Schema<IChat>(
  {
    name: {
      type: String,
      required: function(this: IChat) {
        return this.isGroup
      },
    },
    isGroup: {
      type: Boolean,
      default: false,
    },
    participants: [{
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    }],
    messages: [messageSchema],
    lastMessage: messageSchema,
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  {
    timestamps: true,
  }
)

// Middleware to update lastMessage
chatSchema.pre('save', function(next) {
  if (this.messages.length > 0) {
    this.lastMessage = this.messages[this.messages.length - 1]
  }
  next()
})

// Add any instance methods here
chatSchema.methods.toJSON = function() {
  const obj = this.toObject()
  delete obj.__v
  return obj
}

export const Chat = model<IChat>('Chat', chatSchema) 