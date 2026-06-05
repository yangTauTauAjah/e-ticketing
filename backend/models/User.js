const supabase = require('../config/database');
const bcrypt = require('bcrypt');

class User {
  static async create(userData) {
    try {
      const hashedPassword = await bcrypt.hash(userData.password, 10);

      const { data, error } = await supabase
        .from('users')
        .insert([
          {
            email: userData.email,
            username: userData.username,
            password_hash: hashedPassword,
            name: userData.name,
            phone: userData.phone || null,
            role: userData.role || 'user'
          }
        ])
        .select()
        .single();

      if (error) throw error;

      const { password_hash, ...userWithoutPassword } = data;
      return userWithoutPassword;
    } catch (error) {
      throw error;
    }
  }

  static async findByEmail(email) {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('email', email)
        .single();

      if (error && error.code === 'PGRST116') return null; // Not found
      if (error) throw error;

      return data;
    } catch (error) {
      throw error;
    }
  }

  static async findByUsername(username) {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('username', username)
        .single();

      if (error && error.code === 'PGRST116') return null; // Not found
      if (error) throw error;

      return data;
    } catch (error) {
      throw error;
    }
  }

  static async findById(id) {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', id)
        .single();

      if (error && error.code === 'PGRST116') return null; // Not found
      if (error) throw error;

      return data;
    } catch (error) {
      throw error;
    }
  }

  static async updateProfile(userId, updates) {
    try {
      const { data, error } = await supabase
        .from('users')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', userId)
        .select()
        .single();

      if (error) throw error;

      const { password_hash, ...userWithoutPassword } = data;
      return userWithoutPassword;
    } catch (error) {
      throw error;
    }
  }

  static async updatePassword(userId, newPassword) {
    try {
      const hashedPassword = await bcrypt.hash(newPassword, 10);

      const { error } = await supabase
        .from('users')
        .update({
          password_hash: hashedPassword,
          updated_at: new Date().toISOString()
        })
        .eq('id', userId);

      if (error) throw error;

      return true;
    } catch (error) {
      throw error;
    }
  }

  static async updateLastLogin(userId) {
    try {
      await supabase
        .from('users')
        .update({ last_login: new Date().toISOString() })
        .eq('id', userId);
    } catch (error) {
      // Log but don't throw - non-critical operation
      console.error('Error updating last login:', error);
    }
  }

  static async verifyPassword(plainPassword, hashedPassword) {
    return bcrypt.compare(plainPassword, hashedPassword);
  }

  static async findAllByRole(role) {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('id, name, email, username')
        .eq('role', role)
        .eq('is_active', true)
        .order('name', { ascending: true });

      if (error) throw error;

      return data;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = User;
