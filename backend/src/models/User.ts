import { Schema, model, Document } from 'mongoose'

export interface IUser extends Document {
  googleId: string
  email: string
  name: string
  picture: string
  status: 'online' | 'offline'
  lastSeen: Date
  createdAt: Date
  updatedAt: Date
}

const userSchema = new Schema<IUser>(
  {
    googleId: {
      type: String,
      required: true,
      unique: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    picture: {
      type: String,
      required: true,
    },
    status: {
      type: String,
      enum: ['online', 'offline'],
      default: 'offline',
    },
    lastSeen: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
)

// Create compound text index for fuzzy search
userSchema.index(
  { name: 'text', email: 'text' },
  {
    weights: {
      name: 10, // Give more weight to name matches
      email: 5,  // Less weight to email matches
    },
    name: 'text_search_index'
  }
)

// Add any instance methods here
userSchema.methods.toJSON = function () {
  const obj = this.toObject()
  delete obj.__v
  return obj
}

export const User = model<IUser>('User', userSchema) 