#ifndef LITE_PTR_H
#define LITE_PTR_H

template<typename T>
class lite_ptr
{
public:
    lite_ptr():m_ref(0),m_ptr(0){
        //qDebug()<<"lite_ptr()";
    }
    lite_ptr(const lite_ptr& ptr):m_ref(ptr.m_ref),m_ptr(ptr.m_ptr){
        if(m_ref){
            (*m_ref)++;
        }else{
        }
        //qDebug()<<"lite_ptr(lite_ptr)"<<m_ptr<<"  ref:"<<(m_ref?*m_ref:-10);
    }
    lite_ptr(T* p):m_ptr(p){
        m_ref = new int;
        (*m_ref) = 1;
        //qDebug()<<"lite_ptr(ptr)"<<m_ptr<<"  ref:"<<*m_ref;
    }
    lite_ptr& operator=(const lite_ptr& ptr){
        if(m_ref){
            (*m_ref)--;
            if((*m_ref) <=0 ){
                delete m_ref;
                delete m_ptr;
            }
        }
        m_ref = ptr.m_ref;
        m_ptr = ptr.m_ptr;
        if(m_ref){
            (*m_ref)++;
        }
        //qDebug()<<"lite_ptr = "<<m_ptr<<"  ref:"<<(m_ref?*m_ref:-10);
    }
    ~lite_ptr(){
        if(m_ref){
            (*m_ref)--;
            if((*m_ref) <=0 ){
                delete m_ref;
                m_ref = 0;
                delete m_ptr;
                m_ptr = 0;
            }
        }
        //qDebug()<<"lite_ptr ~ "<<m_ptr<<"  ref:"<<(m_ref?*m_ref:-10);
    }
    T* get() const{
        //qDebug()<<"lite_ptr get "<<m_ptr<<"  ref:"<<(m_ref?*m_ref:-10);
        return m_ptr;
    }
private:
    int* m_ref;
    T*   m_ptr;
};


#endif
